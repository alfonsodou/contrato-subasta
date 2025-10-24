// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Subasta simple
 * @dev Permite pujar por un artículo durante un tiempo limitado.
 */
contract Subasta {
    address public  owner = 0xF55301514c27489Fde7C9cd9A3EA8044E7E04579;
    string  public  description;
    uint256 public  minBid;
    uint256 public  maxBid;
    address public  addressMaxBid;
    uint256 public  deadLine;
    //uint256 public  numBids;
    bool    private bloqueado; // Semáforo para funciones críticas

    mapping (address => uint256) bids;

    // Eventos personalizados
    event Bid(address bidder, uint256 amount);

/*
    // Errores personalizados
    error AuctionEnded(uint256 currentTime, uint256 deadline);
    error AuctionNotEnded(uint256 currentTime, uint256 deadline);
    error AlreadyBid(address bidder);
    error OwnerCannotBid(address owner);
    error BidTooLow(uint256 sent, uint256 minBid);
    error NotHighestBid(uint256 sent, uint256 currentMax);
    error InsufficientBalance(uint256 senderBalance, uint256 required);
    error MaxBidNotRefund(address maxBidder);
    error NotBid(address bidder);
    error NotRefund(address bidder, uint256 amount);
    error NotOwner(address bidder);
    error NotWithdraw(address bidder, uint256 amount);
*/

    /**
     * @notice Crea la subasta
     * @param _description Artículo a subastar.
     * @param _minBid Monto de la puja mínima inicial en wei.
     * @param _minutes Duración de la subasta en minutos.
     */
    constructor (string memory _description, uint256 _minBid, uint256 _minutes) {
        description = _description;
        minBid = _minBid;
        maxBid = 0;
        deadLine = block.timestamp + _minutes * 1 minutes;
        //numBids = 0;
    }    

    /**
     * @notice Realiza una puja
     * @dev La puja debe ser mayor que la actual.
     */
    function makeBid () external payable {
        // Checks

        // Subasta todavía abierta
        require(block.timestamp < deadLine, "Subasta cerrada");
        /*if  (block.timestamp >= deadLine) {
                revert AuctionEnded({
                    currentTime: block.timestamp,
                    deadline:    deadLine
                });
        }*/

        require(msg.value > 0, "Sin envio de bTNB");

        // El propietario no puede pujar en su propia subasta
        require(msg.sender != owner, "El propietario no puede pujar");
        /*if (msg.sender == owner) {
            revert OwnerCannotBid({ owner: owner });
        }*/

        // El remitente aún no ha hecho una oferta
        require(bids[msg.sender] == 0, "Ya realizaste una puja");
        /*if (bids[msg.sender] != 0) {
            revert AlreadyBid({ bidder: msg.sender });
        }*/

        // La oferta debe ser al menos el mínimo inicial exigido
        require(msg.value > minBid, "La puja debe ser mas ata que la puja minima");
        /*if (msg.value < minBid) {
            revert BidTooLow({ sent: msg.value, minBid: minBid });
        }*/

        // La oferta debe superar la máxima actual
        require(msg.value > maxBid, "La puja debe ser mas alta");
        /*if (maxBid >= msg.value) {
            revert NotHighestBid({ sent: msg.value, currentMax: maxBid });
        }*/

        // El ofertante necesita suficiente saldo libre (incluyendo el 0.01 ether de reserva)
        uint256 required = 0.01 ether + msg.value;
        require(required >= msg.sender.balance, "No tienes saldo suficiente");
        /*if (msg.sender.balance < required) {
            revert InsufficientBalance({
                senderBalance: msg.sender.balance,
                required:      required
            });
        }*/

        // Effects
        bids[msg.sender] = msg.value;
        maxBid = msg.value;
        addressMaxBid = msg.sender;
        //numBids++;
        emit Bid(msg.sender, msg.value);
    }

    /**
     * @notice Recupera la puja realizada
     * @dev Solo si la subasta está terminada y no es la puja ganadora.
     */
    function refund () external noReentrancy {
        // Checks

        // Subasta cerrada
        require(block.timestamp > deadLine, "La subasta todavia esta abierta");
        /*if (block.timestamp < deadLine) {
            revert AuctionNotEnded({
                currentTime: block.timestamp,
                deadline:    deadLine
            });
        }*/

        // Puja ganadora
        require(addressMaxBid != msg.sender, "Tu puja es la ganadora. No puedes recuperarla");
        /*if (addressMaxBid == msg.sender) {
            revert MaxBidNotRefund( {maxBidder: msg.sender} );
        }*/

        // No hizo puja
        require(bids[msg.sender] != 0, "No pujaste por este articulo");
        /*if (bids[msg.sender] == 0) {
            revert NotBid( {bidder: msg.sender} );
        }*/
 
        // Effects
        bids[msg.sender] = 0;

        // Interactions
        (bool ok, ) = payable(msg.sender).call{value:bids[msg.sender]}("");
        require(ok, "Fallo al enviar fondos");
        /*if (!ok) {
            revert NotRefund( {
                bidder: msg.sender,
                amount: bids[msg.sender]
            });
        }*/
    }

    /**
     * @notice Recupera importe puja ganadora
     * @dev Solo si la subasta está terminada y es el propietario.
     */
    function ownerWithdraw () external noReentrancy {
        // Checks

        // Es el propietario
        require(msg.sender == owner, "No eres el propietario del articulo");
        /*if (msg.sender != owner) {
            revert NotOwner( {bidder: msg.sender} );
        }*/

        // Subasta cerrada
        require(block.timestamp > deadLine, "La subasta no esta cerrada todavia");
        /*if (block.timestamp < deadLine) {
            revert AuctionNotEnded({
                currentTime: block.timestamp,
                deadline:    deadLine
            });
        }*/
        
        // Se realizaron pujas
        //require(numBids > 0, "No hubo ninguna puja");

        // Effects
        bids[addressMaxBid] = 0;

        // Interactions
        (bool ok, ) = payable(owner).call{value:maxBid}("");
        require(ok, "Fallo al enviar fondos");
        /*if (!ok) {
            revert NotWithdraw({
                bidder: msg.sender,
                amount: maxBid
            });
        }*/
    }

    // Modificador para prevenir ataques de reentrada
    modifier noReentrancy() {
        if (bloqueado) revert();
        bloqueado = true;
        _;
        bloqueado = false;
    }
}