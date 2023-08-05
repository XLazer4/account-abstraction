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
  return <div>DAI Balance is {count}</div>;
};

const Counter: React.FC<Props> = ({ smartAccount, provider }) => {
  const [balance, setBalance] = useState<number>(0);
  const [balanceContract, setBalanceContract] = useState<any>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const investmentVault = "0x41f4DAfA850a8FbB3743f157f4dc7858E483c10A";
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

  const transfer = async () => {
    try {
      toast.info("Processing transfer on the blockchain!", {
        position: "top-right",
        autoClose: 5000,
        hideProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
        draggable: true,
        progress: undefined,
        theme: "dark",
      });

      const transferTx = new ethers.utils.Interface([
        "function transfer(address _to, uint256 _value)",
      ]);
      const receiverAddress = "0x204E7F44b9f6cB9784c865D14a4773d79BF605c4";
      const amountToTransfer = ethers.utils.parseEther("1");
      const data = transferTx.encodeFunctionData("transfer", [
        receiverAddress,
        amountToTransfer,
      ]);

      const tx1 = {
        to: investmentVault,
        data: data,
      };

      let partialUserOp = await smartAccount.buildUserOp([tx1]);

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
      <TotalCountDisplay count={balance} />
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
      <button onClick={() => transfer()}>Transfer Token</button>
    </>
  );
};

export default Counter;
