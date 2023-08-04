import React, { useState, useEffect } from "react";
import { BiconomySmartAccount, SmartAccount } from "@biconomy/account";
import {
  IHybridPaymaster,
  SponsorUserOperationDto,
  PaymasterMode,
} from "@biconomy/paymaster";
import abi from "../utils/counterAbi.json";
import { ethers } from "ethers";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface Props {
  smartAccount: BiconomySmartAccount;
  provider: any;
}

const TotalCountDisplay: React.FC<{ count: number }> = ({ count }) => {
  return <div>Total Balance is {count}</div>;
};

const Counter: React.FC<Props> = ({ smartAccount, provider }) => {
  const [balance, setBalance] = useState<number>(0);
  const [balanceContract, setBalanceContract] = useState<any>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const balanceAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

  useEffect(() => {
    setIsLoading(true);
    getBalance(false);
  }, []);

  const getBalance = async (isUpdating: boolean) => {
    const contract = new ethers.Contract(balanceAddress, abi, provider);
    setBalanceContract(contract);
    let smartAccountAddress = await smartAccount.getSmartAccountAddress();
    const currentBalance = await contract.balanceOf(smartAccountAddress);
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

  // const incrementCount = async () => {
  //   try {
  //     toast.info("Processing count on the blockchain!", {
  //       position: "top-right",
  //       autoClose: 5000,
  //       hideProgressBar: false,
  //       closeOnClick: true,
  //       pauseOnHover: true,
  //       draggable: true,
  //       progress: undefined,
  //       theme: "dark",
  //     });

  //     const incrementTx = new ethers.utils.Interface([
  //       "function incrementCount()",
  //     ]);
  //     const data = incrementTx.encodeFunctionData("incrementCount");

  //     const tx1 = {
  //       to: counterAddress,
  //       data: data,
  //     };

  //     let partialUserOp = await smartAccount.buildUserOp([tx1]);

  //     const biconomyPaymaster =
  //       smartAccount.paymaster as IHybridPaymaster<SponsorUserOperationDto>;

  //     let paymasterServiceData: SponsorUserOperationDto = {
  //       mode: PaymasterMode.SPONSORED,
  //       // optional params...
  //     };

  //     try {
  //       const paymasterAndDataResponse =
  //         await biconomyPaymaster.getPaymasterAndData(
  //           partialUserOp,
  //           paymasterServiceData
  //         );
  //       partialUserOp.paymasterAndData =
  //         paymasterAndDataResponse.paymasterAndData;

  //       const userOpResponse = await smartAccount.sendUserOp(partialUserOp);
  //       const transactionDetails = await userOpResponse.wait();

  //       console.log("Transaction Details:", transactionDetails);
  //       console.log("Transaction Hash:", userOpResponse.userOpHash);

  //       toast.success(`Transaction Hash: ${userOpResponse.userOpHash}`, {
  //         position: "top-right",
  //         autoClose: 5000,
  //         hideProgressBar: false,
  //         closeOnClick: true,
  //         pauseOnHover: true,
  //         draggable: true,
  //         progress: undefined,
  //         theme: "dark",
  //       });

  //       getCount(true);
  //     } catch (e) {
  //       console.error("Error executing transaction:", e);
  //       // ... handle the error if needed ...
  //     }
  //   } catch (error) {
  //     console.error("Error executing transaction:", error);
  //     toast.error("Error occurred, check the console", {
  //       position: "top-right",
  //       autoClose: 5000,
  //       hideProgressBar: false,
  //       closeOnClick: true,
  //       pauseOnHover: true,
  //       draggable: true,
  //       progress: undefined,
  //       theme: "dark",
  //     });
  //   }
  // };

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
      {/* <button onClick={() => incrementCount()}>Increment Count</button> */}
    </>
  );
};

export default Counter;
