// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './HotelBookingInterface.sol';


contract Hotel is Ownable, HotelBookingInterface, ReentrancyGuard {
  
  using Counters for Counters.Counter;

  uint public totalHotels = 0; //the total number of the hotels
  uint public hotelListingFee = 0.00000043 ether;
  Counters.Counter private _hotelIds; //hotel id to be inrecemented when a new hotel is created

  enum HOTEL_CATEGORY {CHAIN_HOTEL, MOTEL, RESORT, INN, ALL_SUITS, BOUTIGUE, EXTENDED_STAY}
  HOTEL_CATEGORY public hotelCategory;
  HOTEL_CATEGORY constant DEFAULT_HOTEL_TYPE = HOTEL_CATEGORY.CHAIN_HOTEL; //default hotel type as it is the most common around the world

  //Group hotel data together in a Struct
  struct HotelItem{
    uint id;
    uint totalRooms;
    uint creationDate;
    string name;
    HOTEL_CATEGORY hotelCategory;
    string description;
    string locationAddress;
    address payable user;
  }

  HotelItem[] public hotelItems; //hotels array of the Hotel struct above
  mapping(uint => HotelItem) public hotelItemId;
  mapping(address => HotelItem) public hotelOwner; //the owner of this hotel
  mapping(uint => bool) public existingHotelItemId;
  mapping(string => bool) public existingHotelItemName;
  

  constructor() {

  }

  //ensure that the hotel exists in the blockchain before performing related transactions
  modifier hotelExists(uint _hotelId){
      require(existingHotelItemId[_hotelId] == true,"Hotel Does Not Exist");
      _;
  }

  //to avoid duplicate hotel names in the contract
  modifier hotelNameExists(string memory _name){
     require(existingHotelItemName[_name] == false,"Hotel Name Exists");
     require(bytes(_name).length > 0,"Please specify the hotel name");
     _;
  }

  //ensure the transaction sender owns this hotel before the transaction
  modifier ownsHotel(uint _hotelId){
      require(msg.sender == hotelItemId[_hotelId].user,"You Do Not Own This Hotel Item");
      _;
  }

  //check that this user address has hotel before adding a room
  modifier hasListedHotel(uint _hotelId){
      bool isListed = false;
        if(msg.sender == hotelItemId[_hotelId].user){
            isListed = true;
        }
      require(isListed == true,"Please List A Hotel Before Adding A Room");
      _;
  }

  function setListingFee(uint _fee) public onlyOwner{
    require(_fee != 0,"Listing Fee Cannot be zero");
    hotelListingFee = _fee;
  }


  function addHotel(string memory _name,string memory _description, string memory _location) public hotelNameExists(_name) nonReentrant payable{
    require(msg.sender != address(0));
    require(msg.value == hotelListingFee,"Invalid Listing Fee");
    require(bytes(_description).length > 0,"Please specify the hotel description");
    require(bytes(_location).length > 0,"Please specify the location of the hotel");
    _hotelIds.increment();
    uint currentHotelId = _hotelIds.current();
    hotelItemId[currentHotelId] = HotelItem(currentHotelId,0, block.timestamp, _name, DEFAULT_HOTEL_TYPE,_description, _location, payable(msg.sender));
    hotelItems.push(hotelItemId[currentHotelId]);
    hotelOwner[msg.sender] = hotelItemId[currentHotelId];
    totalHotels += 1;
    existingHotelItemId[currentHotelId] = true;
    existingHotelItemName[_name] = true;
    payable(owner()).transfer(msg.value);
    //emit HotelCreated(block.timestamp, msg.sender, currentHotelId);
  }

  function listAllHotels() public view returns(HotelItem[] memory){
      return hotelItems;
  }

  function getHotelBioData(uint _hotelId) public view hotelExists(_hotelId) returns(
      uint _id,
      uint _totalRooms,
      uint _date,
      string memory _name,
      string memory _description,
      string memory _location,
      HOTEL_CATEGORY _category
      ){
    HotelItem storage hotelItem = hotelItemId[_hotelId];
    _id = hotelItem.id;
    _totalRooms = hotelItem.totalRooms;
    _date = hotelItem.creationDate;
    _name = hotelItem.name;
    _description = hotelItem.description;
    _location = hotelItem.locationAddress;
    _category = hotelItem.hotelCategory;
  }

  function changeHotelCategory(uint _hotelId, HOTEL_CATEGORY _category) public hotelExists(_hotelId) ownsHotel(_hotelId) {
     HotelItem storage hotelItem = hotelItemId[_hotelId];
     assert(_category != DEFAULT_HOTEL_TYPE);
     assert(_category != hotelItem.hotelCategory);
     hotelItem.hotelCategory = _category;
     //emit HotelCategoryChanged(msg.sender, block.timestamp, _category);
  }

  function getName(uint _hotelId) external virtual view override hotelExists(_hotelId) returns(string memory){
      return hotelItemId[_hotelId].name;
  }

  function getId(uint _hotelId) external virtual view override hotelExists(_hotelId) returns(uint){
      return hotelItemId[_hotelId].id;
  }

  function changeHotelOwner(address payable _newOwner, uint _hotelId) public hotelExists(_hotelId) ownsHotel(_hotelId){
      require(msg.sender != _newOwner,"You are the rightful owner already");
      require(_newOwner != address(0),"Please specify a valid ETH address");
      hotelItemId[_hotelId].user = _newOwner;
      //emit HotelOwnerChanged(msg.sender, _newOwner, block.timestamp);
  }
}
