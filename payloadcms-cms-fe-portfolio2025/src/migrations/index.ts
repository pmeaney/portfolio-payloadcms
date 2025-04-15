import * as migration_20250415_183126 from './20250415_183126';

export const migrations = [
  {
    up: migration_20250415_183126.up,
    down: migration_20250415_183126.down,
    name: '20250415_183126'
  },
];
