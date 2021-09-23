pragma solidity >=0.5.0;

contract Partners {

    mapping (address => address) private _affiliates;
    mapping (address => address[]) private _referrals;
    mapping (address => bool) private _registered;

    event UserRegistered(address indexed account, uint256 amount, address affiliate);

    function _register(address _sender, address _affiliate) internal {
        require(_affiliate != _sender, "Self referral");
        require(_registered[_sender] == false, "User account registered");

        if (_affiliate != address(0)) {
            require(
                _registered[_affiliate] == true,
                "Affiliate account not registered"
            );
        }

        _registered[_sender] = true;
        _affiliates[_sender] = _affiliate;

        if (_affiliate != address(0)) {
            _referrals[_affiliate].push(_sender);
        }

        emit UserRegistered(_sender, msg.value, _affiliate);
    }

    function isUser(address _account) public view returns (bool) {
        return _registered[_account];
    }

    function getAffiliate(address _account) public view returns (address) {
        return _affiliates[_account];
    }

    function getReferrals(address _account) external view returns (address[] memory refs) {
        refs = _referrals[_account];
    }

    function countReferrals(address _account) public view returns (uint256) {
        return _referrals[_account].length;
    }
}
