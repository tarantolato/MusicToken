pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // The account hash of 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for non-contract addresses,
        // so-called Externally Owned Account (EOA)
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You dont have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked for more time");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract TokenNew is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromAntiDipFee;

    mapping (address => bool) private _isExcluded; // esclusione dal reward
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**6 * 10**9; // TOTAL AMOUNT : 100.000.000.000.000 tokens
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private constant MONTH = 2628000; // 31536000/12 ;
    uint256 private constant DAYS = 86400; // 31536000/365 ;
    uint256 private _startTimestamp;
    uint256 private _LockingPeriodDays = 30; // Locking time for locking liquidity in days

    string private _name = "TokenNew";
    string private _symbol = "TKNN";
    uint8 private _decimals = 9;

    bool public _autoMode = false; // allo start disattiva il calcolo della Anti Dip fee tramite Oracolo
    uint256 public _antiDipFee = 0; // variable% taxation in BNB to avoid dips
    uint256 private _previousantiDipFee = _antiDipFee;
    uint256 private _antiDipFeeFromOracle; // percentuale di Anti Dip fee proveniente dall'algoritmo di Oracle


    uint256 public _taxFee = 0; // 3% redistribuition
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 0; // 3% liquidity fee
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _charityFee = 0; // 5% charity fee
    uint256 private _previousCharityFee = _charityFee;

    uint256 public _maxTxAmount = 100000000 * 10**6 * 10**9; // Max transferrable in one transaction (1% of _tTotal after initial burning of 50% of total tokens)

    address public _charityAddress = 0x3136F1Ec8a29b1cF5b5d73f2A1b51658007d8BB3; // Charity address o Singer address
    address public _liquidityAddress = 0x31e1149141534a4ae69283150eEF010826162E60; // Liquidity address
    address public _antiDipAddress = 0x9731ED56e6d13B5220F4DE929f41490b4939AD63; // Anti Dip address

    constructor ()  {
        _rOwned[_msgSender()] = _rTotal;
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_liquidityAddress] = true;
        _isExcludedFromFee[_antiDipAddress] = true;

        //exclude owner and this contract from Anti Dip fee
        _isExcludedFromAntiDipFee[owner()] = true;
        _isExcludedFromAntiDipFee[address(this)] = true;
        _isExcludedFromAntiDipFee[_charityAddress] = true;
        _isExcludedFromAntiDipFee[_liquidityAddress] = true;
        _isExcludedFromAntiDipFee[_antiDipAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: mint to the zero address");
        _tTotal = _tTotal.add(_amount);
         if (_isExcluded[_account]) {
           _tOwned[_account].add(_amount);
         }
         else
         {
            _rOwned[_account].add(_amount);
         }
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: burn from the zero address");
        require(_tTotal >= _amount, "BEP20: total supply must be >= amout");
        _tTotal = _tTotal.sub(_amount);
         if (_isExcluded[_account]) {
              require(_tOwned[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _tOwned[_account].sub(_amount);
         }
         else
         {
              require(_rOwned[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _rOwned[_account].sub(_amount);
         }
        emit Transfer(_account, address(0), _amount);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function getAntiDipFee() public view returns (uint256) {
        return _antiDipFee;
    }

    function getAntiDipAddress() public view returns (address) {
        return _antiDipAddress;
    }

    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function getLiquidityFee() public view returns (uint256) {
        return _liquidityFee;
    }

    function getLiquidityAddress() public view returns (address) {
        return _liquidityAddress;
    }

    function getCharityFee() public view returns (uint256) {
        return _charityFee;
    }

    function getCharityAddress() public view returns (address) {
        return _charityAddress;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function maxTXAmountPerTransfer() public view returns (uint256) {
        return _maxTxAmount;
    }

    function getAntiDipAutoFromOracle() public view returns (bool) {
        return _autoMode;
    }

    function get_antiDipFeeFromOracle() public view returns (uint256) {
        return _antiDipFeeFromOracle;
    }

    function set_antiDipFeeFromOracle(uint256 antiDipFeeFromOracle) public onlyOwner returns (uint256) {
        _antiDipFeeFromOracle = antiDipFeeFromOracle;
        return _antiDipFeeFromOracle;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function setPresaleParameters (
      uint256 _MaxTXPerThousand,
      address payable _newCharityAddress,
      address payable _newLiquidityAddress,
      address payable _newAntiDipAddress,
      bool _antiDipAutoFromOracle

    ) public onlyOwner {
        removeAllFee();
        removeAllAntiDipFee();
        setAntiDipAutoFromOracle(_antiDipAutoFromOracle); // settare a false
        setMaxTxPerThousand(_MaxTXPerThousand);
        changeCharityAddress(_newCharityAddress);
        changeLiquidityAddress(_newLiquidityAddress);
        changeAntiDipAddress(_newAntiDipAddress);
    }

    function setPancakeSwapParameters (uint256 _MaxTXPerThousand, bool _antiDipAutoFromOracle) public onlyOwner {
        restoreAllFee();
        restoreAllAntiDipFee();
        setAntiDipAutoFromOracle(_antiDipAutoFromOracle); // settare a true
        setMaxTxPerThousand(_MaxTXPerThousand);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromAntiDipFee(address account) public onlyOwner {
        _isExcludedFromAntiDipFee[account] = true;
    }

    function includeInAntiDipFee(address account) public onlyOwner {
        _isExcludedFromAntiDipFee[account] = false;
    }

    function setFeePercent(uint256 taxFee, uint256 liquidityFee, uint256 charityFee) external onlyOwner() {
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
        _charityFee = charityFee;
    }

    function setAntiDipFeePercent(uint256 antiDipFee) external onlyOwner {
        _antiDipFee = antiDipFee;
    }

    function setAntiDipAutoFromOracle(bool autoMode) public onlyOwner {
        _autoMode = autoMode;
    }

    function setMaxTxPerThousand(uint256 maxTxThousand) public onlyOwner { // expressed in per thousand and not in percent
        _maxTxAmount = _tTotal.mul(maxTxThousand).div(
            10**3
        );
    }

    function changeCharityAddress(address payable _newaddress) public onlyOwner {
    _charityAddress = _newaddress;
    }

    function changeLiquidityAddress(address payable _newaddress) public onlyOwner {
    _liquidityAddress = _newaddress;
    }

    function changeAntiDipAddress(address payable _newaddress) public onlyOwner {
    _antiDipAddress = _newaddress;
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

////////////////// funzioni di get per il transfer //////////////////////////


    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tCharity = calculateCharityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tCharity);
        return (tTransferAmount, tFee, tLiquidity, tCharity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rCharity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate =  _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
        if(_isExcluded[_charityAddress])
            _tOwned[_charityAddress] = _tOwned[_charityAddress].add(tCharity);
    }

    function _takeAntiDip(uint256 tAntiDip) private {
        uint256 currentRate =  _getRate();
        uint256 rAntiDip = tAntiDip.mul(currentRate);
        _rOwned[_antiDipAddress] = _rOwned[_antiDipAddress].add(rAntiDip);
        if(_isExcluded[_antiDipAddress])
            _tOwned[_antiDipAddress] = _tOwned[_antiDipAddress].add(tAntiDip);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(10**2);
    }

//////////////  questa funzione deve avere il feedback dall'oracolo di Uniswap per definire la fee in funzione dell'allontanamento dal prezzo massimo ////////////////////////
   function calculateAntiDipFee(uint256 _amount) public onlyOwner view returns (uint256) {
       uint256 antiDipResultFee;
       if (!_autoMode) {
           antiDipResultFee = _amount.mul(_antiDipFee).div(10**2);
       }
       else {
           antiDipResultFee = _amount.mul(_antiDipFeeFromOracle).div(10**2);
       }
       return antiDipResultFee;
   }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
    }

    function removeAllAntiDipFee() private {
        if(_antiDipFee == 0) return;
        _previousantiDipFee = _antiDipFee;
        _antiDipFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
    }

    function restoreAllAntiDipFee() private {
        _antiDipFee = _previousantiDipFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromAntiDipFee(address account) public view returns(bool) {
        return _isExcludedFromAntiDipFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

///////////// funzione di transfer per il transfer /////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        //transfer amount, it will take redistribuition fee, charity fee, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeCharity(tCharity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    }


}
