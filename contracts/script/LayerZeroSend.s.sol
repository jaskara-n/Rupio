// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {IOAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import {SendParam, OFTReceipt} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {OptionsBuilder} from "../src/Libraries/OptionsBuilder.sol";
import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {Rupio} from "../src/Rupio.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract SendOFT is Script {
    using OptionsBuilder for bytes;
    HelperConfig helperconfig;

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function run() public {
        // Fetching environment variables
        address oftAddress = 0xC07D0290997f5053923e17B03ab871e9575E5e36;
        address toAddress = 0x12B2434a1022d5787bf06056F2885Fe35De62Bf8;
        uint256 _tokensToSend = 10 * 1e18;

        helperconfig = new HelperConfig();

        // Start broadcasting with the private key
        vm.startBroadcast();

        Rupio sourceOFT = Rupio(oftAddress);

        bytes memory _extraOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(65000, 0);
        SendParam memory sendParam = SendParam(
            helperconfig.getEthSepoliaConfig().chainEid, // You can also make this dynamic if needed
            addressToBytes32(toAddress),
            _tokensToSend,
            (_tokensToSend * 9) / 10,
            _extraOptions,
            "",
            ""
        );

        MessagingFee memory fee = sourceOFT.quoteSend(sendParam, false);

        console.log("Fee amount: ", fee.nativeFee);

        sourceOFT.send{value: fee.nativeFee}(sendParam, fee, msg.sender);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
