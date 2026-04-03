#!/usr/bin/env node
/**
 * Blueprint Swarm — StopFailure Hook
 *
 * Fires when Claude Code hits a rate limit. Saves swarm state to disk
 * so the watchdog can auto-resume after the rate limit window resets.
 *
 * Register in settings.json:
 * {
 *   "hooks": {
 *     "StopFailure": [{
 *       "matcher": "rate_limit",
 *       "hooks": [{
 *         "type": "command",
 *         "command": "node Blueprint-Swarm/hooks/swarm-stop-failure.js"
 *       }]
 *     }]
 *   }
 * }
 */

const fs = require('fs');
const path = require('path');
const { glob } = require('fs').promises ? require('fs') : { glob: null };

// Find the active state.json
function findStateFile() {
  // Search common locations relative to cwd
  const searchPaths = [
    'data',
    'Blueprint-Swarm/data',
  ];

  for (const base of searchPaths) {
    if (!fs.existsSync(base)) continue;

    const entries = fs.readdirSync(base, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const stateFile = path.join(base, entry.name, 'state.json');
      if (fs.existsSync(stateFile)) {
        try {
          const state = JSON.parse(fs.readFileSync(stateFile, 'utf-8'));
          if (state.status === 'in_progress' || state.status === 'running') {
            return stateFile;
          }
        } catch (e) {
          // Skip malformed state files
        }
      }
    }
  }

  // Also check if state.json path is in env
  if (process.env.SWARM_STATE_FILE && fs.existsSync(process.env.SWARM_STATE_FILE)) {
    return process.env.SWARM_STATE_FILE;
  }

  return null;
}

function main() {
  const stateFile = findStateFile();

  if (!stateFile) {
    // No active swarm run — nothing to save
    const result = {
      additionalContext: 'Rate limit hit. No active swarm state found — nothing to save.'
    };
    process.stdout.write(JSON.stringify(result));
    return;
  }

  try {
    const state = JSON.parse(fs.readFileSync(stateFile, 'utf-8'));

    // Update status
    state.status = 'paused';
    state.updated_at = new Date().toISOString();

    // Mark any running agents as interrupted
    if (state.agent_details) {
      for (const [batchId, agent] of Object.entries(state.agent_details)) {
        if (agent.status === 'running') {
          agent.status = 'interrupted';
        }
      }
    }

    // Log the rate limit event
    if (!state.rate_limit_events) {
      state.rate_limit_events = [];
    }
    state.rate_limit_events.push({
      timestamp: new Date().toISOString(),
      reset_time: null, // Watchdog will parse this from the tmux pane
      agents_completed_before: state.agents_completed_total || 0,
      wave_interrupted: state.current_wave || 0
    });

    // Update session log
    if (state.sessions && state.sessions.length > 0) {
      const currentSession = state.sessions[state.sessions.length - 1];
      if (!currentSession.ended_at) {
        currentSession.ended_at = new Date().toISOString();
        currentSession.reason_ended = 'rate_limited';
      }
    }

    // Write state back
    fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));

    // Log to watchdog log if it exists
    const logFile = process.env.WATCHDOG_LOG || '/tmp/swarm-watchdog.log';
    const logMsg = `[${new Date().toISOString()}] StopFailure hook: Rate limit detected. State saved to ${stateFile}. Status: paused.\n`;
    fs.appendFileSync(logFile, logMsg);

    const result = {
      additionalContext: `Rate limit hit. Swarm state saved to ${stateFile} (${state.agents_completed_total || 0}/${state.total_batches || '?'} agents complete). Watchdog will auto-resume after the rate limit window resets.`
    };
    process.stdout.write(JSON.stringify(result));

  } catch (e) {
    const result = {
      additionalContext: `Rate limit hit. Failed to save swarm state: ${e.message}. Manual resume may be needed.`
    };
    process.stdout.write(JSON.stringify(result));
  }
}

main();
