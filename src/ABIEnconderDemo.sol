// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title ABIEncoderDemo
 * @dev A simple contract to demonstrate ABI encoding and decoding in Solidity.
 * ♠@author pablo
 */
contract ABIEncoderDemo {
    //events to show the codification
    event EncodedData(bytes32 indexed poolid, address token, uint256 rate);
    event PoolIdentifierCreated(bytes32 indexed positionId, address user, uint256 amount);
    event UserPositionEncoder(bytes32 indexed positionId, address user, uint256 amount);

    /**
     * @dev this function encode the poolparameters
     * @param tokenA firts pool token
     * @param tokenB second pool token
     * @param fee poll fee
     * @return poolId the encoded pool identifier(unique for this pool  )
     */
    function createdPoolIdentifier(address tokenA, address tokenB, uint24 fee) external pure returns (bytes32 poolId) {
        //we order the tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        //use of ABI.ENCODEPACKED Createduniquepoolidentifier
        poolId = keccak256(abi.encodePacked(token0, token1, fee));
    }

    /**
     *  @dev Encodes data for a trading position, including user address, input token, output token, input amount, and minimum output amount.
     * @param user User address
     * @param tokenIn Imput token
     * @param tokenout Output token
     * @param amountIn Input amount
     * @param minAmountOut Minimum output amount
     * @return positionId position identifier
     * @return encodedData Encoded position data
     */
    function encodeTradingPosition(
        address user,
        address tokenIn,
        address tokenout,
        uint256 amountIn,
        uint256 minAmountOut
    ) external view returns (bytes32 positionId, bytes memory encodedData) {
        //Encode the position data
        encodedData = abi.encodePacked(user, tokenIn, tokenout, amountIn, minAmountOut, block.timestamp);

        //Create a unique position identifier using keccak256 hash of the encoded data
        positionId = keccak256(encodedData);
    }

    /**
     * @dev Encodes swap data for a swap on a DEX.
     * @param path Array of tokens for the swap
     * @param amounts Array of amounts
     * @param deadline Swap deadline
     * @return swapData Encoded swap data
     */
    function encodeSwapData(address[] calldata path, uint256[] calldata amounts, uint256 deadline)
        external
        pure
        returns (bytes memory swapData)
    {
        require(path.length == amounts.length, "Array length mismatch");

        swapData = abi.encode(path, amounts, deadline);
    }

    /**
     * @dev Encodes data for a limit order.
     * @param maker  address
     * @param taker  address
     * @param tokenIn The address of the input token
     * @param tokenOut The address of the output token
     * @param amountIn The amount of the input token
     * @param amountOut The amount of the output token
     * @param nonce A unique nonce for the order
     * @return orderHash A unique hash representing the order
     * @return orderData The encoded order data
     */
    function encodeLimitOrder(
        address maker,
        address taker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 nonce
    ) external pure returns (bytes32 orderHash, bytes memory orderData) {
        //encode the order date
        orderData = abi.encodePacked(maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce, "limit_order_v1");
        orderHash = keccak256(orderData);
    }

    /**
     * @dev Encodes data for a limit order.
     * @param user User address
     * @param poolId identifier
     * @param  amount  Staked amount
     * @param startTime Position start time
     * @return positionId Position Idintifier
     */

    function encodeYieldPosition(address user, bytes32 poolId, uint256 amount, uint256 startTime)
        external
        pure
        returns (bytes32 positionId)
    {
        positionId = keccak256(abi.encodePacked(user, poolId, amount, startTime, "yield Position"));
    }

    function encodeFlashLoanData(address token, uint256 amount, bytes calldata callbackData)
        external
        pure
        returns (bytes memory flashLoansData)
    {
        flashLoansData = abi.encodePacked(token, amount, callbackData, "FLASH_LOAN_V1");
    }
    /**
     * @dev Encodes parameters for a staking pool
     * @param  token Token address
     * @param rewardRate Reward rate
     * @param lockPeriod Lock period
     * @param maxStaker Maximum number of stakers
     *@return  poolConfig Encoded configuration data
     */

    function encodeStakingPoolConfig(address token, uint256 rewardRate, uint256 lockPeriod, uint256 maxStaker)
        external
        view
        returns (bytes memory poolConfig)
    {
        poolConfig = abi.encodePacked(token, rewardRate, lockPeriod, maxStaker, block.timestamp);
    }

    /**
     * @dev Creates a unique hash for a user acrosss multiple pools
     * @param user User address
     * @param  poolIds Array of pool identifiers
     * @return  userHash Unique user hash
     */
    function createdUserMultiPoolHash(address user, bytes32[] calldata poolIds)
        external
        pure
        returns (bytes32 userHash)
    {
        bytes memory data = abi.encodePacked(user);

        for (uint256 i = 0; i < poolIds.length; i++) {
            data = abi.encodePacked(data, poolIds[i]);
        }
        data = abi.encodePacked(data, "MULTI_POOL_USER");
        userHash = keccak256(data);
    }
    /**
     * @dev Encodes data for a yield farming strategy
     * @param strategyName Name of the strategy
     * @param  pools Array of involved pools
     * @param weights Array of weights for each pool
     * @return strategyData Encoded strategy data
     */

    function encodeYieldStrategy(string calldata strategyName, address[] calldata pools, uint256[] calldata weights)
        external
        pure
        returns (bytes memory strategyData)
    {
        require(pools.length == weights.length, "Arrays length mismatch");

        //Encode strategy name
        bytes memory nameData = abi.encodePacked(strategyName);

        //Encode pools
        bytes memory poolsData;
        for (uint256 i = 0; i < pools.length; i++) {
            poolsData = abi.encodePacked(poolsData, pools[i]);
        }

        //Encode weights
        bytes memory weightsData;
        for (uint256 i = 0; i < weights.length; i++) {
            weightsData = abi.encodePacked(weightsData, weights[i]);
        }

        //Combine everything
        strategyData = abi.encodePacked(nameData, poolsData, weightsData, "YIELD_STRATEGY_V1");
    }
    /**
     * @dev demonstrates encoding data for a cross-chain bridge transfer, including source and target chain IDs, token address, amount, and recipient address.
     * @param sourceChain Source chain ID
     * @param targetChain Target chain ID
     * @param token Token address
     * @param amount Amount to transfer
     * @param recipient Recipient address on the target chain
     * @return bridgeData Encoded bridge transfer data
     */

    function encodeCrossChainBrigeData(
        uint256 sourceChain,
        uint256 targetChain,
        address token,
        uint256 amount,
        address recipient
    ) external pure returns (bytes memory bridgeData) {
        bridgeData = abi.encodePacked(sourceChain, targetChain, token, amount, recipient, "CROSS_CHAIN_BRIDGE_V1");
    }

    /**
     * @dev Creates a unique transaction ID for a DeFi transaction by encoding the transaction type, user address, timestamp, and a nonce.
     * @param txType Transaction type
     * @param user User address
     * @param timestamp Transaction timestamp
     * @param nonce Unique nonce for the transaction
     * @return txId Unique transaction ID
     */
    function createDeFiTransactionId(string calldata txType, address user, uint256 timestamp, uint256 nonce)
        external
        pure
        returns (bytes32 txId)
    {
        txId = keccak256(abi.encodePacked(txType, user, timestamp, nonce, "DEFI_TX"));
    }

    /**
     * @dev Encodes data for a stop-loss order, including user address, token address, amount, stop price, and trigger price.
     * @param user User address
     * @param token Token address
     * @param amount Amount to sell
     * @param stopPrice Price at which the stop-loss order should be triggered
     * @param triggerPrice Price at which the order should be executed once triggered
     * @return stopLossData Encoded stop-loss order data
     */
    function encodeStopLossOrder(address user, address token, uint256 amount, uint256 stopPrice, uint256 triggerPrice)
        external
        pure
        returns (bytes memory stopLossData)
    {
        stopLossData = abi.encodePacked(user, token, amount, stopPrice, triggerPrice, "STOP_LOSS_ORDER");
    }

    /**
     * @dev Encodes data for a take profit order
     * @param user User address
     * @param token Token to sell
     * @param amount Amount to sell
     * @param takeProfitPrice Take profit price
     * @return takeProfitData Encoded order data
     */
    function encodeTakeProfitOrder(address user, address token, uint256 amount, uint256 takeProfitPrice)
        external
        pure
        returns (bytes memory takeProfitData)
    {
        takeProfitData = abi.encodePacked(user, token, amount, takeProfitPrice, "TAKE_PROFIT_ORDER");
    }

    /**
     * @dev Encodes data for a trailing stop order
     * @param user User address
     * @param token Token to sell
     * @param amount Amount to sell
     * @param trailingPercent Trailing percentage
     * @param activationPrice Activation price
     * @return trailingStopData Encoded order data
     */
    function encodeTrailingStopOrder(
        address user,
        address token,
        uint256 amount,
        uint256 trailingPercent,
        uint256 activationPrice
    ) external pure returns (bytes memory trailingStopData) {
        trailingStopData = abi.encodePacked(
            user, token, amount, trailingPercent, activationPrice, "TRAILING_STOP_ORDER"
        );
    }
}
