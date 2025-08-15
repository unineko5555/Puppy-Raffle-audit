// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PuppyRaffleMock {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of approve
    function approve(address to, uint256 tokenId) public {
        
    }

    // Mock implementation of changeFeeAddress
    function changeFeeAddress(address newFeeAddress) public {
        
    }

    // Mock implementation of enterRaffle
    function enterRaffle(address[] memory newPlayers) public payable {
        
    }

    // Mock implementation of refund
    function refund(uint256 playerIndex) public {
        
    }

    // Mock implementation of renounceOwnership
    function renounceOwnership() public {
        
    }

    // Mock implementation of safeTransferFrom
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        
    }

    // Mock implementation of safeTransferFrom
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        
    }

    // Mock implementation of selectWinner
    function selectWinner() public {
        
    }

    // Mock implementation of setApprovalForAll
    function setApprovalForAll(address operator, bool approved) public {
        
    }

    // Mock implementation of transferFrom
    function transferFrom(address from, address to, uint256 tokenId) public {
        
    }

    // Mock implementation of transferOwnership
    function transferOwnership(address newOwner) public {
        
    }

    // Mock implementation of withdrawFees
    function withdrawFees() public {
        
    }


    // Mock implementation of receive function
    receive() external payable {}


    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for COMMON_RARITY
    function setCOMMON_RARITYReturn(uint256 _value0) public {
        _COMMON_RARITYReturn_0 = _value0;
    }

    // Function to set return values for LEGENDARY_RARITY
    function setLEGENDARY_RARITYReturn(uint256 _value0) public {
        _LEGENDARY_RARITYReturn_0 = _value0;
    }

    // Function to set return values for RARE_RARITY
    function setRARE_RARITYReturn(uint256 _value0) public {
        _RARE_RARITYReturn_0 = _value0;
    }

    // Function to set return values for balanceOf
    function setBalanceOfReturn(uint256 _value0) public {
        _balanceOfReturn_0 = _value0;
    }

    // Function to set return values for entranceFee
    function setEntranceFeeReturn(uint256 _value0) public {
        _entranceFeeReturn_0 = _value0;
    }

    // Function to set return values for feeAddress
    function setFeeAddressReturn(address _value0) public {
        _feeAddressReturn_0 = _value0;
    }

    // Function to set return values for getActivePlayerIndex
    function setGetActivePlayerIndexReturn(uint256 _value0) public {
        _getActivePlayerIndexReturn_0 = _value0;
    }

    // Function to set return values for getApproved
    function setGetApprovedReturn(address _value0) public {
        _getApprovedReturn_0 = _value0;
    }

    // Function to set return values for isApprovedForAll
    function setIsApprovedForAllReturn(bool _value0) public {
        _isApprovedForAllReturn_0 = _value0;
    }

    // Function to set return values for name
    function setNameReturn(string memory _value0) public {
        _nameReturn_0 = _value0;
    }

    // Function to set return values for owner
    function setOwnerReturn(address _value0) public {
        _ownerReturn_0 = _value0;
    }

    // Function to set return values for ownerOf
    function setOwnerOfReturn(address _value0) public {
        _ownerOfReturn_0 = _value0;
    }

    // Function to set return values for players
    function setPlayersReturn(address _value0) public {
        _playersReturn_0 = _value0;
    }

    // Function to set return values for previousWinner
    function setPreviousWinnerReturn(address _value0) public {
        _previousWinnerReturn_0 = _value0;
    }

    // Function to set return values for raffleDuration
    function setRaffleDurationReturn(uint256 _value0) public {
        _raffleDurationReturn_0 = _value0;
    }

    // Function to set return values for raffleStartTime
    function setRaffleStartTimeReturn(uint256 _value0) public {
        _raffleStartTimeReturn_0 = _value0;
    }

    // Function to set return values for rarityToName
    function setRarityToNameReturn(string memory _value0) public {
        _rarityToNameReturn_0 = _value0;
    }

    // Function to set return values for rarityToUri
    function setRarityToUriReturn(string memory _value0) public {
        _rarityToUriReturn_0 = _value0;
    }

    // Function to set return values for supportsInterface
    function setSupportsInterfaceReturn(bool _value0) public {
        _supportsInterfaceReturn_0 = _value0;
    }

    // Function to set return values for symbol
    function setSymbolReturn(string memory _value0) public {
        _symbolReturn_0 = _value0;
    }

    // Function to set return values for tokenIdToRarity
    function setTokenIdToRarityReturn(uint256 _value0) public {
        _tokenIdToRarityReturn_0 = _value0;
    }

    // Function to set return values for tokenURI
    function setTokenURIReturn(string memory _value0) public {
        _tokenURIReturn_0 = _value0;
    }

    // Function to set return values for totalFees
    function setTotalFeesReturn(uint256 _value0) public {
        _totalFeesReturn_0 = _value0;
    }

    // Function to set return values for totalSupply
    function setTotalSupplyReturn(uint256 _value0) public {
        _totalSupplyReturn_0 = _value0;
    }


    /*******************************************************************
     *   ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️  *
     *-----------------------------------------------------------------*
     *      Generally you only need to modify the sections above.      *
     *          The code below handles system operations.              *
     *******************************************************************/

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  STRUCT DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event Approval(address owner, address approved, uint256 tokenId);
    event ApprovalForAll(address owner, address operator, bool approved);
    event FeeAddressChanged(address newFeeAddress);
    event OwnershipTransferred(address previousOwner, address newOwner);
    event RaffleEnter(address[] newPlayers);
    event RaffleRefunded(address player);
    event Transfer(address from, address to, uint256 tokenId);

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    uint256 private _COMMON_RARITYReturn_0;
    uint256 private _LEGENDARY_RARITYReturn_0;
    uint256 private _RARE_RARITYReturn_0;
    uint256 private _balanceOfReturn_0;
    uint256 private _entranceFeeReturn_0;
    address private _feeAddressReturn_0;
    uint256 private _getActivePlayerIndexReturn_0;
    address private _getApprovedReturn_0;
    bool private _isApprovedForAllReturn_0;
    string private _nameReturn_0;
    address private _ownerReturn_0;
    address private _ownerOfReturn_0;
    address private _playersReturn_0;
    address private _previousWinnerReturn_0;
    uint256 private _raffleDurationReturn_0;
    uint256 private _raffleStartTimeReturn_0;
    string private _rarityToNameReturn_0;
    string private _rarityToUriReturn_0;
    bool private _supportsInterfaceReturn_0;
    string private _symbolReturn_0;
    uint256 private _tokenIdToRarityReturn_0;
    string private _tokenURIReturn_0;
    uint256 private _totalFeesReturn_0;
    uint256 private _totalSupplyReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of COMMON_RARITY
    function COMMON_RARITY() public view returns (uint256) {
        return _COMMON_RARITYReturn_0;
    }

    // Mock implementation of LEGENDARY_RARITY
    function LEGENDARY_RARITY() public view returns (uint256) {
        return _LEGENDARY_RARITYReturn_0;
    }

    // Mock implementation of RARE_RARITY
    function RARE_RARITY() public view returns (uint256) {
        return _RARE_RARITYReturn_0;
    }

    // Mock implementation of balanceOf
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOfReturn_0;
    }

    // Mock implementation of entranceFee
    function entranceFee() public view returns (uint256) {
        return _entranceFeeReturn_0;
    }

    // Mock implementation of feeAddress
    function feeAddress() public view returns (address) {
        return _feeAddressReturn_0;
    }

    // Mock implementation of getActivePlayerIndex
    function getActivePlayerIndex(address player) public view returns (uint256) {
        return _getActivePlayerIndexReturn_0;
    }

    // Mock implementation of getApproved
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApprovedReturn_0;
    }

    // Mock implementation of isApprovedForAll
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _isApprovedForAllReturn_0;
    }

    // Mock implementation of name
    function name() public view returns (string memory) {
        return _nameReturn_0;
    }

    // Mock implementation of owner
    function owner() public view returns (address) {
        return _ownerReturn_0;
    }

    // Mock implementation of ownerOf
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOfReturn_0;
    }

    // Mock implementation of players
    function players(uint256 arg0) public view returns (address) {
        return _playersReturn_0;
    }

    // Mock implementation of previousWinner
    function previousWinner() public view returns (address) {
        return _previousWinnerReturn_0;
    }

    // Mock implementation of raffleDuration
    function raffleDuration() public view returns (uint256) {
        return _raffleDurationReturn_0;
    }

    // Mock implementation of raffleStartTime
    function raffleStartTime() public view returns (uint256) {
        return _raffleStartTimeReturn_0;
    }

    // Mock implementation of rarityToName
    function rarityToName(uint256 arg0) public view returns (string memory) {
        return _rarityToNameReturn_0;
    }

    // Mock implementation of rarityToUri
    function rarityToUri(uint256 arg0) public view returns (string memory) {
        return _rarityToUriReturn_0;
    }

    // Mock implementation of supportsInterface
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterfaceReturn_0;
    }

    // Mock implementation of symbol
    function symbol() public view returns (string memory) {
        return _symbolReturn_0;
    }

    // Mock implementation of tokenIdToRarity
    function tokenIdToRarity(uint256 arg0) public view returns (uint256) {
        return _tokenIdToRarityReturn_0;
    }

    // Mock implementation of tokenURI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIReturn_0;
    }

    // Mock implementation of totalFees
    function totalFees() public view returns (uint256) {
        return _totalFeesReturn_0;
    }

    // Mock implementation of totalSupply
    function totalSupply() public view returns (uint256) {
        return _totalSupplyReturn_0;
    }

}