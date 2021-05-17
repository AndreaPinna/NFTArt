// contracts/galleria.sol
// SPDX-License-Identifier: CC-BY-4.0
/// @title NFT-ART - PSAB2021
/// @author Andrea Pinna


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 

import "@openzeppelin/contracts/utils/Counters.sol";


contract gallery is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address systemOwner; /* system owner address */
    uint basePrice = 1000 wei;
    uint256 private lastID;
    enum artworkState {IN_COMPOSITION, VIEW_ONLY, ON_SALE}
 
    // Lista di opere d'arte
    struct ArtWorkList{
        uint256[] artWorks;
    }
    

    // struttura dati del token artWork
    struct ArtWork {
        uint256 artworkID;
        artworkState state; 
        string artistName;
        string artURI;
        uint256 price;
        address buyer;
    }
    
    

    mapping(address => ArtWorkList) internal artWorksPerArtist;
    mapping(uint256 => ArtWork) private artWork;
    mapping(address => uint256) private artistBalance;
  
    event newBuyer(address, uint);
    event Received(address, uint);
    event Received_Data(address, uint, bytes );
    
  

    constructor() ERC721("Art Works NFT", "AWN")  {
        systemOwner = msg.sender;
        
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    fallback() external payable {
        emit Received_Data(msg.sender, msg.value, msg.data);
    }
    
    modifier onlySystemOwner(){
        require(systemOwner==msg.sender);
        _;
    }
    
    modifier onlyTokenOwner(uint256 id){
        require(ownerOf(id)==msg.sender);
        _;
    }
    
    modifier checkValue(){
        require(msg.value == basePrice,"Please pay exactly the base price");
        _;
    }
    
    
    function setBasePrice(uint256 newBasePrice)
        public 
        onlySystemOwner
    {
        basePrice = newBasePrice;
        
    }
    
    
    function createToken()
        public 
        payable
        checkValue
        returns (uint256)
    {
        /* standard token mint */
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, "");
        lastID=newItemId;
  
         /* creating token info */
         artWork[newItemId]=
            ArtWork(
            newItemId,
            artworkState.IN_COMPOSITION,
            "",
            "",
            basePrice,
            address(0));
    
        artWorksPerArtist[msg.sender].artWorks.push(newItemId);


        return newItemId; //qrcode
    }
    
    function artWorkSet (
        uint256 artworkID,
        string memory artistName,
        string memory artURI,
        uint256 price
        ) 
        public
        onlyTokenOwner(artworkID)
    {
        require(
            artWork[artworkID].state == 
            artworkState.IN_COMPOSITION, 
            "Invalid state: state must be IN_COMPOSITION. ");
            
        artWork[artworkID]=
            ArtWork(
            artworkID,
            artworkState.IN_COMPOSITION,
            artistName,
            artURI,
            price,
            address(0));
    
    }
    
    function artWorkSetSealed (
        uint256 artworkID
        ) 
        public
        onlyTokenOwner(artworkID)
    {
        require(
            artWork[artworkID].state == 
            artworkState.IN_COMPOSITION, 
            "Invalid state: state must be IN_COMPOSITION. ");
            
        artWork[artworkID].state = artworkState.VIEW_ONLY;
    }
    
    function artWorkSetOnSale (
        uint256 artworkID
        ) 
        public
        onlyTokenOwner(artworkID)
    {
        require(
            artWork[artworkID].state == 
            artworkState.VIEW_ONLY, 
            "Invalid state: state must be VIEW_ONLY. ");
            
        artWork[artworkID].state = artworkState.ON_SALE;
        approve(address(this), artworkID);
    
    }
    
    function buyReqArtWork(uint256 artworkID)
        public
        payable
    {
        require(
            artWork[artworkID].state == 
            artworkState.ON_SALE, 
            "Invalid state: state must be ON_SALE");
     
        require(
            artWork[artworkID].buyer == address(0), 
            "Someone is already buying it");
     
            
        require(
            msg.value == artWork[artworkID].price,
            "You must pay the exact price");
        
        artWork[artworkID].buyer = msg.sender;
        emit newBuyer(msg.sender,artworkID);
    }

    function sellArtWork(uint256 artworkID)
        public
        payable
        onlyTokenOwner(artworkID)
        {
        require(
            artWork[artworkID].state == 
            artworkState.ON_SALE, 
            "Invalid state: state must be ON_SALE");
        require(
            artWork[artworkID].buyer != address(0), 
            "No one is buying it");
            
        artistBalance[ownerOf(artworkID)] = artistBalance[ownerOf(artworkID)] + artWork[artworkID].price;
        artWork[artworkID].state=artworkState.VIEW_ONLY;
        
        deleteFromArtisArray(msg.sender, artworkID);
        artWorksPerArtist[artWork[artworkID].buyer].artWorks.push(artworkID);

        
        
        safeTransferFrom(msg.sender,artWork[artworkID].buyer, artworkID);
        
    }
    
    function deleteFromArtisArray(address artist, uint256 artworkID)
        private
        {   
            uint256 index;
            for(uint i; i< artWorksPerArtist[artist].artWorks.length; i++){
                if(artWorksPerArtist[artist].artWorks[i] == artworkID){
                    index = i;
                    
                }
            }
            artWorksPerArtist[artist].artWorks[index] = artWorksPerArtist[artist].artWorks[artWorksPerArtist[artist].artWorks.length-1];
            delete artWorksPerArtist[artist].artWorks[artWorksPerArtist[artist].artWorks.length-1];
        }
        

    
    function getBalanceContract()  
            public 
            view 
            onlySystemOwner
            returns (uint) {
        return address(this).balance;
    }
    
    
    function getBalanceArtist()
            public 
            view 
            returns (uint) {
            return artistBalance[msg.sender];
            }
    
     function getArtWorksNumber()
            public 
            view 
            returns (uint256 artWorksNumber) {
            return lastID;
            }
            
    function getBasePrice()
            public 
            view 
            returns (uint256 basePriceWei) {
            return basePrice;
            }
            
    function getArtWorksPerArtistList()
            public 
            view 
            returns (uint256[] memory artWorksList) {
            return artWorksPerArtist[msg.sender].artWorks;
            }
    
    function getArtWorkData(uint256 artWorkId) 
        public 
        view
        returns(ArtWork memory artWorkData) 
    {
        return(artWork[artWorkId]);
        
    }
    

    
}
