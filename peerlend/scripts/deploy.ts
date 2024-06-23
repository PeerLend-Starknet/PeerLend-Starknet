import { Account, CallData, Contract, RpcProvider, stark } from "starknet";
import * as dotenv from "dotenv";
import { getCompiledCode } from "./utils";
dotenv.config();

async function main() {
    const provider = new RpcProvider({
        nodeUrl: process.env.RPC_ENDPOINT,
    });

    // initialize existing predeployed account 0
    console.log("ACCOUNT_ADDRESS=", process.env.DEPLOYER_ADDRESS);
    console.log("ACCOUNT_PRIVATE_KEY=", process.env.DEPLOYER_PRIVATE_KEY);
    const privateKey0 = process.env.DEPLOYER_PRIVATE_KEY ?? "";
    const accountAddress0: string = process.env.DEPLOYER_ADDRESS ?? "";
    const account0 = new Account(provider, accountAddress0, privateKey0);
    console.log("Account connected.\n");

    // Declare & deploy contract
    let sierraCode, casmCode;

    try {
        ({ sierraCode, casmCode } = await getCompiledCode("peerlend_Peerlend"));
    } catch (error: any) {
        console.log("Failed to read contract files");
        process.exit(1);
    }

    const myCallData = new CallData(sierraCode.abi);
    const constructor = myCallData.compile("constructor", {
        owner: process.env.DEPLOYER_ADDRESS ?? "",
        datafeed: "0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a",
    });
    const deployResponse = await account0.declareAndDeploy({
        contract: sierraCode,
        casm: casmCode,
        constructorCalldata: constructor,
        salt: stark.randomAddress(),
    });

    // Connect the new contract instance :
    const peerlendContract = new Contract(
        sierraCode.abi,
        deployResponse.deploy.contract_address,
        // "0x5d8431fa7c1118bb2785f628e4d6cb0d768ef8b8e86daee5607097be66988c8",
        provider
    );
    console.log(
        `✅ Contract has been deploy with the address: ${peerlendContract.address}`
    );

    const loanableTokensAddress = [
        "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", // eth
        "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d", // strk
        "0x046fF386120F78C66847934C632E9844c7DAE2ece7088f957b03D44bc1B644b0", // usdc //custom token
    ]

    const assetId = [
        "ETH/USD",
        "STRK/USD",
        "USDC/USD"
    ]

    const loanableTokensCallData = myCallData.compile("set_loanable_tokens", {
        tokens: loanableTokensAddress,
        asset_id: assetId
    });

    const calldata = peerlendContract.populate('set_loanable_tokens', [loanableTokensAddress, assetId]);

    peerlendContract.connect(account0);

    await peerlendContract.set_loanable_tokens(calldata.calldata);

    console.log("✅ Loanable tokens set");
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
