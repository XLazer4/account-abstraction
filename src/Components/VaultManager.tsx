import React, { useState, useEffect } from "react";
import { BiconomySmartAccount, SmartAccount } from "@biconomy/account";
import {
  IHybridPaymaster,
  SponsorUserOperationDto,
  PaymasterMode,
} from "@biconomy/paymaster";
import vaultABI from "../utils/vaultABI.json";
import tokenABI from "../utils/tokenABI.json";
import { ethers } from "ethers";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface Props {
  smartAccount: BiconomySmartAccount;
  provider: any;
}

enum Actions {
  TokenSwap,
  AaveSupply,
  AaveWithdraw,
  GainsDeposit,
  GainsWithdrawRequest,
  GainsEpochForceNewEpoch,
  GainsRedeem,
  PrimexDeposit,
  PrimexWithdraw,
}

const VaultManager: React.FC<Props> = ({ smartAccount, provider }) => {
  const [DAIBalance, setDAIBalance] = useState<number>(0);
  const [USDTBalance, setUSDTBalance] = useState<number>(0);
  const [USDCBalance, setUSDCBalance] = useState<number>(0);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [depositAmount, setDepositAmount] = useState<string>("0");
  const [investorAddress, setInvestorAddress] = useState<string>("");
  const [tokenFromName, setTokenFromName] = useState<string>("");
  const [tokenToName, setTokenToName] = useState<string>("");
  const [stepsString, setStepsString] = useState<string>("");

  const investmentVault = "0xEa492396df4a15B6ead05028995E3e16bE2ab743";
  const DAI = "0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3";
  const USDT = "0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0";
  const USDC = "0x19D66Abd20Fb2a0Fc046C139d5af1e97F09A695e";

  const tokenMap: { [key: string]: string } = {
    DAI: DAI,
    USDT: USDT,
    USDC: USDC,
  };

  useEffect(() => {
    setIsLoading(true);
    getBalance(false);
  }, []);

  function renderActions() {
    return Object.keys(Actions)
      .filter((action) => isNaN(Number(action)))
      .map((action, index) => (
        <div key={index}>
          {action} - {Actions[action as keyof typeof Actions]}
        </div>
      ));
  }

  const getBalance = async (isUpdating: boolean) => {
    const DAIToken = new ethers.Contract(DAI, tokenABI, provider);

    const vaultDaiBalance = await DAIToken.balanceOf(investmentVault);
    const vaultDaiBalanceInEther = ethers.utils.formatEther(vaultDaiBalance);
    setDAIBalance(parseFloat(vaultDaiBalanceInEther));

    const USDTToken = new ethers.Contract(USDT, tokenABI, provider);

    const vaultUSDTBalance = await USDTToken.balanceOf(investmentVault);
    const vaultUSDTBalanceInUnits = ethers.utils.formatUnits(
      vaultUSDTBalance,
      6
    );
    setUSDTBalance(parseFloat(vaultUSDTBalanceInUnits));

    const USDCToken = new ethers.Contract(USDC, tokenABI, provider);

    const vaultUSDCBalance = await USDCToken.balanceOf(investmentVault);
    const vaultUSDCBalanceInUnits = ethers.utils.formatUnits(
      vaultUSDCBalance,
      6
    );
    setUSDCBalance(parseFloat(vaultUSDCBalanceInUnits));

    if (isUpdating) {
      toast.success("Balance has been updated!", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });
    }
  };

  const executeInvestmentPlan = async () => {
    try {
      const _tokenToSwapFrom = tokenMap[tokenFromName];
      const _swapToTokenAddress = tokenMap[tokenToName];

      toast.info("Processing deposit on the blockchain!", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });

      const stepsArray = stepsString.split(",").map((s) => parseInt(s.trim()));
      console.log(stepsArray);
      const executePlanInterface = new ethers.utils.Interface([
        "function executeInvestmentPlan(address investorAddress, address _tokenToSwapFrom, address _swapToTokenAddress, uint256 _amount, uint8[] memory steps)",
      ]);

      const executePlanData = executePlanInterface.encodeFunctionData(
        "executeInvestmentPlan",
        [
          investorAddress,
          _tokenToSwapFrom,
          _swapToTokenAddress,
          depositAmount,
          stepsArray,
        ]
      );

      console.log(
        investorAddress,
        _tokenToSwapFrom,
        _swapToTokenAddress,
        depositAmount,
        stepsArray
      );

      const executeTx = {
        to: investmentVault,
        data: executePlanData,
      };

      let partialUserOp = await smartAccount.buildUserOp([executeTx]);

      const biconomyPaymaster =
        smartAccount.paymaster as IHybridPaymaster<SponsorUserOperationDto>;

      let paymasterServiceData: SponsorUserOperationDto = {
        mode: PaymasterMode.SPONSORED,
        // optional params...
      };

      try {
        const paymasterAndDataResponse =
          await biconomyPaymaster.getPaymasterAndData(
            partialUserOp,
            paymasterServiceData
          );
        partialUserOp.paymasterAndData =
          paymasterAndDataResponse.paymasterAndData;

        const userOpResponse = await smartAccount.sendUserOp(partialUserOp);
        const transactionDetails = await userOpResponse.wait();

        console.log("Transaction Details:", transactionDetails);
        console.log("Transaction Hash:", userOpResponse.userOpHash);

        toast.success(`Transaction Hash: ${userOpResponse.userOpHash}`, {
          position: "top-right",
          autoClose: 5000,
          hideProgressBar: false,
          closeOnClick: true,
          pauseOnHover: true,
          draggable: true,
          progress: undefined,
          theme: "dark",
        });

        getBalance(true);
      } catch (e) {
        console.error("Error executing transaction:", e);
        // ... handle the error if needed ...
      }
    } catch (error) {
      console.error("Error executing transaction:", error);
      toast.error("Error occurred, check the console", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });
    }
  };

  return (
    <>
      <div>DAI Balance: {DAIBalance}</div>
      <div>USDT Balance: {USDTBalance}</div>
      <div>USDC Balance: {USDCBalance}</div>
      <ToastContainer
        position="top-right"
        autoClose={5000}
        hideProgressBar={true}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="dark"
      />
      <br></br>
      <div>
        <h3>Actions:</h3>
        {renderActions()}
      </div>
      <br></br>
      <input
        type="text"
        value={investorAddress}
        onChange={(e) => setInvestorAddress(e.target.value)}
        placeholder="Enter investor address"
      />
      <br></br>
      <input
        type="text"
        value={tokenFromName}
        onChange={(e) => setTokenFromName(e.target.value)}
        placeholder="Enter token to swap from (e.g. DAI)"
      />
      <br></br>
      <input
        type="text"
        value={tokenToName}
        onChange={(e) => setTokenToName(e.target.value)}
        placeholder="Enter token to swap to (e.g. USDT)"
      />
      <br></br>
      <input
        type="number"
        value={depositAmount}
        onChange={(e) => setDepositAmount(e.target.value)}
        placeholder="Enter amount"
      />
      <br></br>
      <input
        type="text"
        value={stepsString}
        onChange={(e) => setStepsString(e.target.value)}
        placeholder="Enter steps (e.g. 1,3,2)"
      />
      <br></br>
      <button onClick={() => executeInvestmentPlan()}>Execute Plan</button>
      <button onClick={() => getBalance(true)}>Refresh Balance</button>
    </>
  );
};

export default VaultManager;
