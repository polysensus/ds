import { inspect } from 'util';
import { DawnseekersClient, Tile, State, PluginTrust, PluginType, useDawnseekersState, BiomeKind } from '../lib/exp-ds-worker-client/src/host';
import fetch from 'cross-fetch';
import WebSocket from 'ws';
import { Observer } from 'zen-observable-ts';

class DawnSeekersBridge implements Observer<State> {

    private _ds: DawnseekersClient;

    constructor() {
        this._ds = new DawnseekersClient({
            wsEndpoint: 'ws://localhost:8080/query',
            httpEndpoint: 'http://localhost:8080/query',
            autoloadablePlugins: [
                // this would be fetched from cog-services
                {
                    type: PluginType.BUILDING,
                    trust: PluginTrust.UNTRUSTED,
                    addr: 'my-building-kind-addr',
                    src: ``,
                },
            ],
            corePlugins: [],
            fetch,
            webSocketImpl: WebSocket
        });

        this._ds.subscribe(this);
    }

    public next(state: State) {
        state = this.breakCircularReferences(state) as State;

        const json = JSON.stringify(state, (key, value) => {
            if (typeof value === 'bigint') {
                return "0x" + BigInt(value).toString(16);
            }
            return value;
        });

        process.stdout.write(json + '\n');
    }

    private breakCircularReferences(obj: any, ancestorSet?: Array<any>) {       
        const seen: Array<any> = [];
        if (ancestorSet) {
            seen.push(...ancestorSet);
        }

        if (seen.indexOf(obj) > -1) {
            const idx = seen.indexOf(obj);
            return null;
        }

        seen.push(obj);

        const newObj = Array.isArray(obj) ? [] : {};

        for (var key in obj) {
            const value = obj[key];
            if (typeof value === 'object' && value !== null) {
                const newVal = this.breakCircularReferences(value, seen);
                if (newVal !== null) {
                    newObj[key] = newVal;
                }
            }
            else
            {
                newObj[key] = obj[key];
            }
        }

        return newObj;
    }

    private simpleBreakCircularReferences(obj: any) {
        for (let key in obj) {
            obj[key] = JSON.parse(JSON.stringify(obj[key], this.getCircularReplacer()));
        }

        return obj;
    }

    private getCircularReplacer() {
        const seen = new WeakSet();
        return (key, value) => {

            if (typeof value === 'bigint') {
                return "0x" + BigInt(value).toString(16);
            }

            if (typeof value === 'object' && value !== null) {
                if (seen.has(value)) {
                    return;
                }
                seen.add(value);
            }

            return value;
        };
    };
}

const bridge = new DawnSeekersBridge();