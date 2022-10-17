import * as React from "react";
import PlugConnect from '@psychedelic/plug-connect';
import {canisterId as tokenCanister, idlFactory} from "../../declarations/ext20"
import {_SERVICE} from "../../declarations/ext20/ext20.did";
import {Modal, Spinner} from "react-bootstrap";
import {atom, useRecoilState} from "recoil";
import {
    hostAtom,
    canisterAtom,
    connectedAtom,
    loadingAtom
} from "./atoms";

const App: React.FC = () => {
    const [host, setHost] = useRecoilState(hostAtom);
    const [canister, setCanister] = useRecoilState(canisterAtom);
    const [connected, setConnected] = useRecoilState(connectedAtom);
    const [loading, setLoading] = useRecoilState(loadingAtom);

    React.useEffect(() => {
        setCanister([tokenCanister]);
        console.log((window as any).ic.plug);
    }, []);

    const isDevelopment = process.env.NODE_ENV !== "production";
    if (isDevelopment) {
        console.log("started in dev");
        setHost("http://127.0.0.1:8000/");
    }

    async function afterConnected() {
        setConnected(true);
        console.log((window as any).ic.plug);
    }

    async function mint() {
        // Initialise Agent, expects no return value
        setLoading(true);
        await (window as any)?.ic?.plug?.requestConnect({
            whitelist: canister,
            host: host
        });

        const NNSUiActor: _SERVICE = await (window as any).ic.plug.createActor({
            canisterId: tokenCanister,
            interfaceFactory: idlFactory,
        });
        const resp = await NNSUiActor.mint((window as any)?.ic?.plug?.accountId);
        console.log(resp);
        setLoading(false);
    }

    return (
        <>
          <div className="d-flex flex-column min-vh-100 justify-content-center align-items-center">
            <h1>Tutorial Token</h1>
            <p>Mint Some Tutorial Tokens</p>
            <p>Add EXT token to your wallet: <strong>{tokenCanister}</strong></p>
            <a href="https://github.com/cryptoisgood/TOKENTUTORIAL">Github</a>
            {!connected && 
            <PlugConnect
                            dark
                            whitelist={canister}
                            host={host}
                            onConnectCallback={afterConnected}
                        />
            }
            {connected && 
            <button onClick={mint} className="btn btn-primary">Mint Tokens</button>
            }
            
          </div>
          <Modal
                show={loading}
                size="sm"
                aria-labelledby="contained-modal-title-vcenter"
                centered
            >
                <Modal.Header>
                    <Modal.Title id="contained-modal-title-vcenter">
                        Minting
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <Spinner animation="border" role="status">
                        <span className="visually-hidden">Loading...</span>
                    </Spinner>
                </Modal.Body>
            </Modal>
        </>
    );
}

export default App