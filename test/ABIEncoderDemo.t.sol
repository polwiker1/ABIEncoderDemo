// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ABIEncoderDemo} from "../src/ABIEnconderDemo.sol";

contract ABIEncoderDemoTest is Test {
    ABIEncoderDemo internal demo;

    function setUp() public {
        demo = new ABIEncoderDemo();
    }

    function testEncodeSwapDataCanBeDecoded() public view {
        address[] memory path = new address[](2);
        path[0] = address(0xA);
        path[1] = address(0xB);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        uint256 deadline = 1_800_000_000;
        bytes memory swapData = demo.encodeSwapData(path, amounts, deadline);

        (address[] memory decodedPath, uint256[] memory decodedAmounts, uint256 decodedDeadline) =
            abi.decode(swapData, (address[], uint256[], uint256));

        assertEq(decodedPath, path);
        assertEq(decodedAmounts, amounts);
        assertEq(decodedDeadline, deadline);
    }

    function testEncodeSwapDataRevertsWhenArrayLengthsDiffer() public {
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](1);

        vm.expectRevert("Array length mismatch");
        demo.encodeSwapData(path, amounts, 1_800_000_000);
    }

    function test_encodeSwapData_EncodesPathAmountsDeadline() external view {
        address[] memory path = new address[](3);
        path[0] = address(0xA);
        path[1] = address(0xB);
        path[2] = address(0xC);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;
        amounts[2] = 3 ether;

        uint256 deadline = 1_800_000_000;

        bytes memory swapData = demo.encodeSwapData(path, amounts, deadline);

        (address[] memory decodedPath, uint256[] memory decodedAmounts, uint256 decodedDeadline) =
            abi.decode(swapData, (address[], uint256[], uint256));

        assertEq(decodedPath, path);
        assertEq(decodedAmounts, amounts);
        assertEq(decodedDeadline, deadline);
    }

    function test_encodeSwapData_RevertsOnLengthMismatch() external {
        address[] memory path = new address[](2);
        path[0] = address(0xA);
        path[1] = address(0xB);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;
        vm.expectRevert("Array length mismatch");
        demo.encodeSwapData(path, amounts, 1_800_000_000);
    }

    function testPoolIdentifierDoesNotDependOnTokenOrder() public view {
        bytes32 tokenAB = demo.createdPoolIdentifier(address(0xA), address(0xB), 3000);
        bytes32 tokenBA = demo.createdPoolIdentifier(address(0xB), address(0xA), 3000);

        assertEq(tokenAB, tokenBA);
    }

    function testTradingPositionHashMatchesEncodedData() public {
        vm.warp(1_800_000_000);

        (bytes32 positionId, bytes memory encodedData) =
            demo.encodeTradingPosition(address(1), address(2), address(3), 10 ether, 9 ether);

        assertEq(positionId, keccak256(encodedData));
    }

    function testLimitOrderHashMatchesEncodedData() public view {
        (bytes32 orderHash, bytes memory orderData) =
            demo.encodeLimitOrder(address(1), address(2), address(3), address(4), 10 ether, 9 ether, 1);

        assertEq(orderHash, keccak256(orderData));
    }

    function testYieldPositionCreatesExpectedIdentifier() public view {
        bytes32 poolId = keccak256("pool");
        bytes32 positionId = demo.encodeYieldPosition(address(1), poolId, 10 ether, 1_800_000_000);
        bytes32 expected = keccak256(
            abi.encodePacked(address(1), poolId, uint256(10 ether), uint256(1_800_000_000), "yield Position")
        );

        assertEq(positionId, expected);
    }

    function testPoolIdentifierChangesWhenFeeChanges() public view {
        bytes32 fee3000 = demo.createdPoolIdentifier(address(0xA), address(0xB), 3000);
        bytes32 fee500 = demo.createdPoolIdentifier(address(0xA), address(0xB), 500);

        assertNotEq(fee3000, fee500);
    }

    /// @dev Multi-pool user hash is keccak of user + all pool ids + discriminator
    function test_createUserMultiPoolHash() external view {
        address user = address(0xCafe);

        bytes32[] memory pools = new bytes32[](3);
        pools[0] = keccak256(abi.encodePacked("P0"));
        pools[1] = keccak256(abi.encodePacked("P1"));
        pools[2] = keccak256(abi.encodePacked("P2"));

        bytes memory data = abi.encodePacked(user);
        for (uint256 i = 0; i < pools.length; i++) {
            data = abi.encodePacked(data, pools[i]);
        }
        data = abi.encodePacked(data, "MULTI_POOL_USER");

        bytes32 expected = keccak256(data);
        bytes32 actual = demo.createdUserMultiPoolHash(user, pools);
        assertEq(actual, expected, "multi pool user hash mismatch");
    }

    function test_encodeFlashLoanData() external view {
        address token = address(0xF1);
        uint256 amount = 100 ether;
        bytes memory callbackData = abi.encode("repay");

        bytes memory actual = demo.encodeFlashLoanData(token, amount, callbackData);
        bytes memory expected = abi.encodePacked(token, amount, callbackData, "FLASH_LOAN_V1");

        assertEq(actual, expected, "flash loan data encoding mismatch");
    }

    function test_encodeStakingPoolConfig() external {
        vm.warp(1_800_000_000);

        address token = address(0x51);
        uint256 rewardRate = 10;
        uint256 lockPeriod = 30 days;
        uint256 maxStaker = 100;

        bytes memory actual = demo.encodeStakingPoolConfig(token, rewardRate, lockPeriod, maxStaker);
        bytes memory expected = abi.encodePacked(token, rewardRate, lockPeriod, maxStaker, block.timestamp);

        assertEq(actual, expected, "staking pool config encoding mismatch");
    }

    /// @dev Yield strategy requires equal-length arrays and returns packed bytes with discriminator
    function test_encodeYieldStrategy_HappyPath() external view {
        string memory name = "StratAlpha";

        address[] memory pools = new address[](2);
        pools[0] = address(0x10);
        pools[1] = address(0x20);

        uint256[] memory weights = new uint256[](2);
        weights[0] = 60;
        weights[1] = 40;

        bytes memory actual = demo.encodeYieldStrategy(name, pools, weights);

        bytes memory nameData = abi.encodePacked(name);
        bytes memory poolsData;
        for (uint256 i = 0; i < pools.length; i++) {
            poolsData = abi.encodePacked(poolsData, pools[i]);
        }
        bytes memory weightsData;
        for (uint256 j = 0; j < weights.length; j++) {
            weightsData = abi.encodePacked(weightsData, weights[j]);
        }

        bytes memory expected = abi.encodePacked(nameData, poolsData, weightsData, "YIELD_STRATEGY_V1");

        assertEq(actual, expected, "yield strategy encoding mismatch");
    }

    /// @dev Mismatched pools/weights must revert with the exact message
    function test_encodeYieldStrategy_RevertsOnLengthMismatch() external {
        string memory name = "Broken";

        address[] memory pools = new address[](2);
        pools[0] = address(0x10);
        pools[1] = address(0x20);

        uint256[] memory weights = new uint256[](1);
        weights[0] = 100;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Arrays length mismatch"));
        demo.encodeYieldStrategy(name, pools, weights);
    }

    /// @dev Cross-chain bridge data is a simple packed concatenation with discriminator
    function test_encodeCrossChainBridgeData() external view {
        uint256 sourceChain = 1;
        uint256 targetChain = 137;
        address token = address(0xFEED);
        uint256 amount = 777;
        address recipient = address(0xBEEF);

        bytes memory actual = demo.encodeCrossChainBrigeData(sourceChain, targetChain, token, amount, recipient);

        bytes memory expected =
            abi.encodePacked(sourceChain, targetChain, token, amount, recipient, "CROSS_CHAIN_BRIDGE_V1");

        assertEq(actual, expected, "bridge data encoding mismatch");
    }

    /// @dev Transaction id is keccak of packed fields plus discriminator
    function test_createDeFiTransactionId() external view {
        string memory txType = "SWAP";
        address user = address(0xABCD);
        uint256 timestamp = 123456789;
        uint256 nonce = 9;

        bytes32 actual = demo.createDeFiTransactionId(txType, user, timestamp, nonce);

        bytes32 expected = keccak256(abi.encodePacked(txType, user, timestamp, nonce, "DEFI_TX"));

        assertEq(actual, expected, "defi transaction id mismatch");
    }

    /// @dev Stop loss order data must match packed encoding with discriminator
    function test_encodeStopLossOrder() external view {
        address user = address(0x01);
        address token = address(0x02);
        uint256 amount = 1_000;
        uint256 stopPrice = 95;
        uint256 triggerPrice = 90;

        bytes memory actual = demo.encodeStopLossOrder(user, token, amount, stopPrice, triggerPrice);
        bytes memory expected = abi.encodePacked(user, token, amount, stopPrice, triggerPrice, "STOP_LOSS_ORDER");

        assertEq(actual, expected, "stop loss order encoding mismatch");
    }

    /// @dev Take profit order data must match packed encoding with discriminator
    function test_encodeTakeProfitOrder() external view {
        address user = address(0x03);
        address token = address(0x04);
        uint256 amount = 2_000;
        uint256 takeProfitPrice = 120;

        bytes memory actual = demo.encodeTakeProfitOrder(user, token, amount, takeProfitPrice);
        bytes memory expected = abi.encodePacked(user, token, amount, takeProfitPrice, "TAKE_PROFIT_ORDER");

        assertEq(actual, expected, "take profit order encoding mismatch");
    }

    /// @dev Trailing stop order data must match packed encoding with discriminator
    function test_encodeTrailingStopOrder() external view {
        address user = address(0x05);
        address token = address(0x06);
        uint256 amount = 3_000;
        uint256 trailingPercent = 5; // 5%
        uint256 activationPrice = 110;

        bytes memory actual = demo.encodeTrailingStopOrder(user, token, amount, trailingPercent, activationPrice);
        bytes memory expected =
            abi.encodePacked(user, token, amount, trailingPercent, activationPrice, "TRAILING_STOP_ORDER");

        assertEq(actual, expected, "trailing stop order encoding mismatch");
    }
}
