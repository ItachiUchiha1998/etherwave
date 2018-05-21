pragma solidity ^0.4.19;

import "./TicketOwnership.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title TicketFactory
 * @dev TicketFactory is a contract for managing the token ownership,
 * allowing the participants to purchase NFT with ether.
 * @author Paula Mannes
 */
contract TicketFactory is Ownable, TicketOwnership {    
    using SafeMath for uint;

    struct Ticket {
        string description;
        //bytes32 referenceCode;
        uint256 dateTime;
        bool isValid;    
    }
    Ticket[] public tickets;

    struct Event {
        string name;
        uint256 dateTime;
        uint256 price;
        uint256 ticketsAvailable;
        uint256 supply;
    }
    Event[] public events;

    /* Events */
    event TicketCreated(address indexed owner, uint indexed ticketId); 
    event EventCreated(uint indexed eventId, string indexed name, uint256 dateTime, uint256 price, uint256 supply);    
    event EventPriceChanged(uint256 eventId, uint256 price);
    
    /* Mappings */
    mapping (uint => address) public eventToAdmin;

    /**
     * @dev Make a purchase of a ticket, receives the eth value
     *      when the same as the current price of the ticket. 
     *      Call ERC721BasicToken.sol function _mint()
     * @param _eventId event id
     * @param _buyer addres of the buyer
     * @return uint ticket created id
     */
    function purchase(
        uint256 _eventId,
        address _buyer
    )
        public
        payable
        returns (uint256)
    {
        require(_eventId != 0);
        require(_buyer != address(0));
        
        Event storage eventInstance = events[_eventId];
        require(eventInstance.price == msg.value);
        
        uint256 dateTime = eventInstance.dateTime;
        //bytes32 referenceCode = keccak256(eventInstance.name, _buyer);
        string storage description = eventInstance.name;
        

        //Update Event
        eventInstance.ticketsAvailable--;
        uint id = tickets.push(Ticket(description, dateTime, true)) - 1;
        
        _mint(_buyer, id);
        emit TicketCreated(_buyer, id);
        return id;
    }

    /**
     * @dev Create a new event
     * @param _name event name
     * @param _dateTime event date
     * @param _price event tickets price
     * @param _supply initial supply
     * @param _admin address of the event admin
     * @return uint event's id
     */
    function createEvent(
        string _name, 
        uint256 _dateTime, 
        uint256 _price,
        uint256 _supply,
        address _admin
    ) 
        public 
        onlyOwner()
        returns (uint256) 
    {
        uint id = events.push(Event(_name, _dateTime, _price, _supply, _supply)) - 1;
        eventToAdmin[id] = _admin;
        emit EventCreated(id, _name, _dateTime,_price, _supply);
        return id;
    }

    /**
     * @dev The number of an event's tickets still available for purchase
     * @param _eventId event number id
     * @return uint256 number of tickets
     */
    function ticketsRemainedOf(uint256 _eventId) public view returns (uint256) {
        return events[_eventId].ticketsAvailable;
    }
        
    /**
     * @dev The price of an event ticket
     * @param _eventId event number id
     * @return uint256 current price of the event's ticket
     */
    function priceOf(uint256 _eventId) public view returns (uint256) {
        return events[_eventId].price;
    }

    /**
     * @dev Set the current price for an event
     * @param _eventId product id
     * @param _price product price
     */
    function setPrice(uint256 _eventId, uint256 _price) public onlyOwner() {
        require(ticketsRemainedOf(_eventId) > 0);
        events[_eventId].price = _price;
        emit EventPriceChanged(_eventId, _price);
    }

}