// Brainrot Breakout — the hand-in program for make.fun's
// roblox-brainrot-01 bounty (Node 22, standard library only).
//
// The game itself is the Rojo project in this directory: build it
// first with `rojo build default.project.json --output game.rbxl`,
// then this program gathers the entry and writes it out. It copies
// the built place, the Luau source, the screenshots and PLAY.json
// from beside this file into the output directory, and writes
// dossier.json there with the vendored make.fun library — the
// summary the judge reads. The output directory is /output when
// the grader runs it; locally, MAKEFUN_OUTPUT_DIR stands in for
// it, so the same command the grader uses works here:
//
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// One rule shapes the whole copy: every name under the output must
// start with a letter, a digit or an underscore, and hold only
// letters, digits, dots, underscores and dashes. A stray dotfile
// such as .gitkeep or .DS_Store anywhere under the output fails
// the entry outright, so the copy skips every path whose name
// starts with a dot, at any depth, in both copied trees.

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

// The repository root is the directory this file lives in.
const repoRoot = fileURLToPath(new URL('.', import.meta.url));
// The grader gives us /output; a local run points here instead.
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// Keep a path only when its last segment does not start with a dot.
function isVisibleName(path: string): boolean {
  return !basename(path).startsWith('.');
}

// Fail loudly, instead of handing in a half-built entry, when a
// file the entry needs is missing from the repository.
function requireFile(name: string): string {
  const path = join(repoRoot, name);
  if (!existsSync(path)) {
    throw new Error(`Brainrot Breakout: missing required file ${name} — build the game first (rojo build) before running main.ts.`);
  }
  return path;
}

mkdirSync(outputDir, { recursive: true });

// The place file and the play link go over as single files.
copyFileSync(requireFile('game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(requireFile('PLAY.json'), join(outputDir, 'PLAY.json'));

// The Luau source and the screenshots go over as whole trees,
// minus anything dot-named.
cpSync(requireFile('src'), join(outputDir, 'src'), { recursive: true, filter: isVisibleName });
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoRoot, 'screenshots'))) {
  cpSync(join(repoRoot, 'screenshots'), join(outputDir, 'screenshots'), { recursive: true, filter: isVisibleName });
}

// A last sanity look at what we just copied: the dossier builder
// refuses an entry the scorer would refuse (more than 4
// screenshots, one over 256 KiB, a place past 500,000 instances,
// scripts past 8 MiB of source or 1,048,576 path characters), so a
// bad build fails here, in our own run, instead of at the gate.
const shotCount = readdirSync(join(outputDir, 'screenshots')).filter(isVisibleName).length;
if (shotCount < 1 || shotCount > 4) {
  throw new Error(`Brainrot Breakout: expected 1 to 4 screenshots, found ${shotCount}.`);
}

writeFileSync(
  join(outputDir, 'dossier.json'),
  buildDossier(outputDir, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);

console.log(`Brainrot Breakout handed in: game.rbxl, src/, ${shotCount} screenshots and PLAY.json written to ${outputDir}, dossier.json built.`);
