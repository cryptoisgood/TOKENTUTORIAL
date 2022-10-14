
const App: React.FC = () => {

    // const [initiated, setIsInitiated] = useRecoilState(isInitiatedAtom);
    // const [loading, setLoading] = useRecoilState(loadingAtom);
    // const [connected] = useRecoilState(connectedAtom);
    // const [canister, setCanister] = useRecoilState(canisterAtom);
    // const [isAdmin, setIsAdmin] = useRecoilState(isAdminAtom);
    // const [host, setHost] = useRecoilState(hostAtom);
    // const [minted, setMinted] = useRecoilState(mintedAtom);

    // const isDevelopment = process.env.NODE_ENV !== "production";
    // if (isDevelopment) {
    //     console.log("started in dev");
    //     setHost("http://127.0.0.1:8000/");
    // }

    // useEffect(() => {
    //     setCanister([nftCanister, candyMachineCanister]);
    //     checkInit().then();
    // }, []);

    // async function checkInit() {
    //     console.log("checked if initiated")
    //     const isInitiated = await isInit();
    //     console.log(isInitiated);
    //     if (isInitiated) {
    //         setIsInitiated(true);
    //     }
    // }


    return (
        <>
            <div className={"title-align viewp"}>
                {/* {isAdmin &&
                    <AdminConfig></AdminConfig>
                } */}
                <Navb></Navb>
                <PageTitle/>
                <Routes>
                    <Route
                        path='mint'
                        element={<Mint />}
                        />
                    <Route
                        path='town'
                        element={<Town />}
                        />
                    <Route
                        path='status'
                        element={<Status />}
                        />
                    <Route
                        path='mintConfirmation'
                        element={<MintConfirmation />}
                        />
                    <Route
                        path='battle'
                        element={<Battle />}
                        />
                    <Route
                        path='*'
                        element={<Home />}
                        />
                </Routes>
            </div>
        </>
    );
}

export default App