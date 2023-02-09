# Dawn Seekers Frontend

HTML layer which the basic auth flow and a test Unity display 

## Structure

```
├── _templates          <-- Hygen code generation templates
├── public              <-- Static files for NextJS to serve
└── src
│   ├── components
│   ├── helpers
│   ├── pages
│   ├── styles          <-- Theme and other global styles
│   └── types           <-- Project global types and interfaces
└─── typings            <-- Type overrides and declarations
```

## Local Development

### Requirements

| Tool    | Version      | Notes                                                                                   |
| :------ | :----------- | :-------------------------------------------------------------------------------------- |
| NodeJS  | `lts/erbium` | Easy version management via [nvm]. Version will be auto-selected if using zsh on MacOS.

### Setup

-   Run `nvm use` in order to switch to the defined project version of NodeJS
-   Run `npm ci` from the root of the repository.

### Running locally

Run the dev server `npm run dev` which will start the NextJS application.

### Code Style & Linting

[Prettier] handles code style and is complimented by [ESLint] that runs in CI, or by running `npm run lint`.

### Theming Bootstrap

The Bootstrap theme is loaded through Emotion as a single CSS file `./src/styles/bootstrap-theme.css`. Don't edit it manually, go to [Bootstrap Magic] and generate a theme.

Copy the generated CSS theme file and the SCSS variables files into `./src/styles/bootstrap-theme.css` and `./src/styles/bootstrap-variables.scss`. You can then reload and edit your theme on Bootstrap Magic using your variables file.

### Code generation via Hygen

#### Getting started

React components and pages can be generated using [hygen].

Running the following command will create a `Modal` component in `./src/components/molecules`

```bash
$ npx hygen component new --type molecule --name modal
```

All the required component files are generated including styles.

```bash
./src/components/molecules/modal
-- index.tsx
-- modal.styles.ts
```

#### Component types

There are four types of component: `atom`, `molecule`, `organism` and `view` which also have the shorthand aliases `a`, `m` `o`, and `v`.

Atom is the default if the `--type` switch is omitted.

Different kinds of components can be generated like so:

**Atoms**

Atoms live in `./src/components/atoms`

```bash
$ npx hygen component new --type atom --name tab
$ npx hygen component new --type a --name tab
```

**Molecules**

Molecules live in `./src/components/molecules`

```bash
$ npx hygen component new --type molecule --name tab-group
$ npx hygen component new --type m --name tab-group
```

**Organisms**

Organisms live in `./src/components/organisms`

```bash
$ npx hygen component new --type organism --name tabbed-content
$ npx hygen component new --type o --name tabbed-content
```

**Views**

Views live in `./src/components/views`

```bash
$ npx hygen component new --type view --name home
$ npx hygen component new --type v --name home
```

#### Pages

Running the following command will create a `Home` page in `./src/pages`

```bash
$ npx hygen page new --name home
```

```bash
./src/pages
-- home.tsx
```

#### Contexts

Running the following command will create a `SomeContext` context provider in `./src/contexts`

```bash
$ npx hygen context new --name some-context
```

```bash
./src/contexts
-- some-context-provider.tsx
```

### Generating contract helpers

The [ethers] compatible contract types and factory helpers are generated by
[typechain]. These enable type hints and bake in the contract ABI making it
easier to work with contract calls from typescript code.

These currently require manually updating if the contracts change. The
intention is to move this manual step into the hardhat compile step, but at
time of writing there is a bug in hardhat typechain plugin that prevents this.

To rebuild the generated `src/services/contracts` files, first ensure you have
compiled the contracts with hardhat:

```
(cd ../solidity && npx hardhat compile)
```

then run the `build:contracts` script to regenerate the types/helpers:

```
npm run build:contracts
```

[nvm]: https://github.com/creationix/nvm
[prettier]: https://prettier.io/
[eslint]: https://eslint.org/
[hygen]: https://www.hygen.io
[ethers]: https://docs.ethers.io/v5/
[typechain]: https://github.com/dethcrypto/TypeChain