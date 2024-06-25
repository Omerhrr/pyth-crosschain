// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title PythMath library
/// @author Omerhrr
/// @notice A library for mathematical operations with prices
library PythMath {
    uint256 constant PD_EXPO = 9; // Scale factor exponent
    uint256 constant PD_SCALE = 1_000_000_000; // Scale factor
    uint256 constant MAX_PD_V_U64 = (1 << 28) - 1; // Maximum value for uint64
    uint256 constant MAX_EXPO = 18; // Maximum exponent

    struct Price {
        uint256 price; // Price value
        uint256 conf; // Confidence interval
        uint256 expo; // Exponent
        uint256 publishTime; // Publish timestamp
    }

    /**
     * @notice Returns the maximum of two numbers
     * @param a The first number
     * @param b The second number
     * @return The maximum of the two numbers
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @notice Scales the price to the target exponent
     * @param price The original price
     * @param fromExpo The original exponent
     * @param toExpo The target exponent
     * @return The scaled price
     */
    function scalePrice(uint256 price, uint256 fromExpo, uint256 toExpo) internal pure returns (uint256) {
        if (fromExpo < toExpo) {
            return price / (10 ** (toExpo - fromExpo));
        } else if (fromExpo > toExpo) {
            return price * (10 ** (fromExpo - toExpo));
        }
        return price;
    }

    /**
     * @notice Adds two prices with the same exponent
     * @param price1 The first price
     * @param price2 The second price
     * @return The combined price
     */
    function addPrices(Price memory price1, Price memory price2) internal pure returns (Price memory) {
        require(price1.expo == price2.expo, "Exponents must be equal");

        uint256 combinedPrice = price1.price + price2.price;
        uint256 combinedConf = price1.conf + price2.conf;

        return Price({
            price: combinedPrice,
            conf: combinedConf,
            expo: price1.expo,
            publishTime: max(price1.publishTime, price2.publishTime)
        });
    }

    /**
     * @notice Subtracts two prices with the same exponent
     * @param price1 The first price
     * @param price2 The second price
     * @return The combined price
     */
    function subPrices(Price memory price1, Price memory price2) internal pure returns (Price memory) {
        require(price1.expo == price2.expo, "Exponents must be equal");

        uint256 combinedPrice = price1.price - price2.price;
        uint256 combinedConf = price1.conf + price2.conf;

        return Price({
            price: combinedPrice,
            conf: combinedConf,
            expo: price1.expo,
            publishTime: max(price1.publishTime, price2.publishTime)
        });
    }

    /**
     * @notice Multiplies two prices
     * @param price1 The first price
     * @param price2 The second price
     * @return The combined price
     */
    function mulPrices(Price memory price1, Price memory price2) internal pure returns (Price memory) {
        uint256 combinedExpo = price1.expo + price2.expo;
        require(combinedExpo <= MAX_EXPO, "Exponent too large");

        uint256 combinedPrice = (price1.price * price2.price) / PD_SCALE;
        uint256 combinedConf = (price1.conf * price2.price + price2.conf * price1.price) / PD_SCALE;

        return Price({
            price: combinedPrice,
            conf: combinedConf,
            expo: combinedExpo,
            publishTime: max(price1.publishTime, price2.publishTime)
        });
    }

    /**
     * @notice Divides two prices
     * @param price1 The first price
     * @param price2 The second price
     * @return The combined price
     */
    function divPrices(Price memory price1, Price memory price2) internal pure returns (Price memory) {
        uint256 combinedExpo = price1.expo - price2.expo;
        require(combinedExpo >= 0, "Exponent too small");

        uint256 combinedPrice = (price1.price * PD_SCALE) / price2.price;
        uint256 combinedConf = (price1.conf * PD_SCALE + price2.conf * price1.price) / price2.price;

        return Price({
            price: combinedPrice,
            conf: combinedConf,
            expo: combinedExpo,
            publishTime: max(price1.publishTime, price2.publishTime)
        });
    }

    /**
     * @notice Combines two prices (used for converting between prices)
     * @param price1 The first price
     * @param price2 The second price
     * @return The combined price
     */
    function combinePrices(Price memory price1, Price memory price2) internal pure returns (Price memory) {
        return divPrices(price1, price2);
    }
}
