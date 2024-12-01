import { marpCli } from '@marp-team/marp-cli';
import markdownItKroki from '@kazumatu981/markdown-it-kroki';

/** @type {import('@marp-team/marp-cli').Config} */
const config = {
  allowLocalFiles: true,
  engine: ({ marp }) => marp.use(markdownItKroki, {
    inputDir: './slides',
    entrypoint: "https://kroki.io",
  }),
};

export default config;