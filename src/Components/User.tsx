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

const TotalCountDisplay: React.FC<{ count: number }> = ({ count }) => {
  return <div>User's DAI Balance: {count}</div>;
};

const User: React.FC<Props> = ({ smartAccount, provider }) => {
  const [balance, setBalance] = useState<number>(0);
  const [vaultBalance, setVaultBalance] = useState<number>(0);
  const [balanceContract, setBalanceContract] = useState<any>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [depositAmount, setDepositAmount] = useState<string>("0");

  const investmentVault = "0xb2d3f2daB9e9d231C0faa4a6BCC3c58730476A79";
  const DAI = "0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3";

  useEffect(() => {
    setIsLoading(true);
    getBalance(false);
  }, []);

  const getBalance = async (isUpdating: boolean) => {
    const token = new ethers.Contract(DAI, tokenABI, provider);
    setBalanceContract(token);
    let smartAccountAddress = await smartAccount.getSmartAccountAddress();
    const currentBalance = await token.balanceOf(smartAccountAddress);
    const currentBalanceInEther = ethers.utils.formatEther(currentBalance);
    setBalance(parseFloat(currentBalanceInEther));

    const vaultDaiBalance = await token.balanceOf(investmentVault);
    const vaultDaiBalanceInEther = ethers.utils.formatEther(vaultDaiBalance);
    setVaultBalance(parseFloat(vaultDaiBalanceInEther));

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

  const deposit = async () => {
    try {
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

      const approveTxInterface = new ethers.utils.Interface([
        "function approve(address spender, uint256 value)",
      ]);
      const approveData = approveTxInterface.encodeFunctionData("approve", [
        investmentVault,
        ethers.utils.parseEther(depositAmount),
      ]);

      const approveTx = {
        to: DAI,
        data: approveData,
      };

      const depositTxInterface = new ethers.utils.Interface([
        "function deposit(address tokenAddress, uint256 _amount)",
      ]);
      const depositData = depositTxInterface.encodeFunctionData("deposit", [
        DAI,
        ethers.utils.parseEther(depositAmount),
      ]);

      const depositTx = {
        to: investmentVault,
        data: depositData,
      };

      let partialUserOp = await smartAccount.buildUserOp([
        approveTx,
        depositTx,
      ]);

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

  const withdraw = async () => {
    try {
      toast.info("Processing withdrawal on the blockchain!", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });

      const withdrawTxInterface = new ethers.utils.Interface([
        "function withdraw(address tokenAddress, uint256 _amount)",
      ]);
      const withdrawData = withdrawTxInterface.encodeFunctionData("withdraw", [
        DAI,
        ethers.utils.parseEther(depositAmount),
      ]);

      const withdrawTx = {
        to: investmentVault,
        data: withdrawData,
      };

      let partialUserOp = await smartAccount.buildUserOp([withdrawTx]);

      const biconomyPaymaster =
        smartAccount.paymaster as IHybridPaymaster<SponsorUserOperationDto>;

      let paymasterServiceData: SponsorUserOperationDto = {
        mode: PaymasterMode.SPONSORED,
        // optional params...
      };

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

  const addVaultManager = async () => {
    try {
      toast.info("Adding Vault Manager", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });

      const addVaultManagerTxInterface = new ethers.utils.Interface([
        "function addVaultManager(address _vaultManager)",
      ]);
      const addVaultManagerData = addVaultManagerTxInterface.encodeFunctionData(
        "addVaultManager",
        [depositAmount]
      );

      const addVaultManagerTx = {
        to: investmentVault,
        data: addVaultManagerData,
      };

      let partialUserOp = await smartAccount.buildUserOp([addVaultManagerTx]);

      const biconomyPaymaster =
        smartAccount.paymaster as IHybridPaymaster<SponsorUserOperationDto>;

      let paymasterServiceData: SponsorUserOperationDto = {
        mode: PaymasterMode.SPONSORED,
        // optional params...
      };

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

  const setAllowance = async () => {
    try {
      toast.info("Setting allowance on the blockchain!", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });

      const setAllowanceInterface = new ethers.utils.Interface([
        "function setAllowance(uint256 _amountAllowed)",
      ]);
      const parsedDepositAmount = parseInt(depositAmount);
      const setAllowanceData = setAllowanceInterface.encodeFunctionData(
        "setAllowance",
        [parsedDepositAmount]
      );

      const setAllowanceDataTx = {
        to: investmentVault,
        data: setAllowanceData,
      };

      let partialUserOp = await smartAccount.buildUserOp([setAllowanceDataTx]);

      const biconomyPaymaster =
        smartAccount.paymaster as IHybridPaymaster<SponsorUserOperationDto>;

      let paymasterServiceData: SponsorUserOperationDto = {
        mode: PaymasterMode.SPONSORED,
        // optional params...
      };

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
      <TotalCountDisplay count={balance} />
      <div>Vault's DAI Balance: {vaultBalance}</div>
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
      <input
        type="text"
        value={depositAmount}
        onChange={(e) => setDepositAmount(e.target.value)}
        placeholder="Enter amount"
      />
      <br></br>
      <button onClick={() => deposit()}>Deposit Token</button>
      <button onClick={() => withdraw()}>Withdraw Token</button>
      <button onClick={() => getBalance(true)}>Refresh Balance</button>
      <button onClick={() => addVaultManager()}>Add Vault Manager</button>
      <button onClick={() => setAllowance()}>Set Allowance</button>
    </>
  );
};

export default User;
