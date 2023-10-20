/** @format */

import { createGlobalStyle } from 'styled-components';
import { resetStyles } from './reset.styles';
import 'bootstrap-icons/font/bootstrap-icons.css';
import { colorMap } from './colors';

export const GlobalStyles = createGlobalStyle`
    ${resetStyles}

    button {
        cursor: pointer;
    }

    i {
        color: inherit;
    }

    // TODO tidy these styles up

    body {
        margin: 0;
        font-family: 'Recursive', monospace;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        background: ${colorMap.documentBackground};
        font-size: 1.478rem;
    }

    .build-version {
        position: fixed;
        bottom: 1rem;
        right: 1rem;
        opacity: 0.5;
        font-size: 1.3rem;
    }

    code {
        font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
        monospace;
    }

    h1, h2, h3, h4 {
        /* text-transform: uppercase; */
    }

    h2 {
        font-size: 2.4rem;
    }

    h3 {
        margin-bottom: 2rem;
    }

    form {
        width: 100%;
    }

    .icon-button {
        background: none;
        border: 0;
        padding: 0;
        border-radius: 0;
        width: auto;
    }

    .link-button {
        display: inline;
        background: none;
        border: 0;
        padding: 0;
        border-radius: 0;
        width: auto;
        color: white;
    }

    form {
        width: 100%;

        .select {
            position: relative;
            width: 100%;

            select {
                appearance: none;
                box-sizing: border-box;
                background-color: #143063;
                border: 1px solid white;
                border-radius: 0.5rem;
                padding: 1rem;
                margin: 0;
                width: 100%;
                font-family: inherit;
                font-size: inherit;
                cursor: inherit;
                line-height: inherit;
                color: white;
            }

            &:after {
                position: absolute;
                top: 50%;
                right: 1.6rem;
                transform: translateY(-50%);
                z-index: 10;
                content: "";
                width: 0.8em;
                height: 0.5em;
                background-color: white;
                clip-path: polygon(100% 0%, 0 0%, 50% 100%);
            }
        }
    }

/* find another theme: https://unpkg.com/browse/highlightjs@9.16.2/styles/ */
/* Tomorrow Night Blue Theme */
/* http://jmblog.github.com/color-themes-for-google-code-highlightjs */
/* Original theme - https://github.com/chriskempson/tomorrow-theme */
/* http://jmblog.github.com/color-themes-for-google-code-highlightjs */

/* Tomorrow Comment */
.hljs-comment,
.hljs-quote {
  color: #7285b7;
}

/* Tomorrow Red */
.hljs-variable,
.hljs-template-variable,
.hljs-tag,
.hljs-name,
.hljs-selector-id,
.hljs-selector-class,
.hljs-regexp,
.hljs-deletion {
  color: #ff9da4;
}

/* Tomorrow Orange */
.hljs-number,
.hljs-built_in,
.hljs-builtin-name,
.hljs-literal,
.hljs-type,
.hljs-params,
.hljs-meta,
.hljs-link {
  color: #ffc58f;
}

/* Tomorrow Yellow */
.hljs-attribute {
  color: #ffeead;
}

/* Tomorrow Green */
.hljs-string,
.hljs-symbol,
.hljs-bullet,
.hljs-addition {
  color: #d1f1a9;
}

/* Tomorrow Blue */
.hljs-title,
.hljs-section {
  color: #bbdaff;
}

/* Tomorrow Purple */
.hljs-keyword,
.hljs-selector-tag {
  color: #ebbbff;
}

.hljs {
  display: block;
  overflow-x: auto;
  background: #002451;
  color: white;
  padding: 0.5em;
}

.hljs-emphasis {
  font-style: italic;
}

.hljs-strong {
  font-weight: bold;
}
`;
