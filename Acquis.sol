pragma solidity ^0.5.3;
import "browser/SafeMath.sol";


contract Acquis {
    using SafeMath for uint256;
    
    address payable proprio;             //  Propiètaire du contrat
    address payable nouveauProprio;      //  tmp pour la passation éventuelle de pouvoir

    event changementProprio ( address indexed _de, address indexed _a );

    modifier propriosSeulement {
        require ( msg.sender == proprio );
        _;
    }

//  PROPRIETAIRE
    function changerProprio ( address payable _nouveauProprio ) public propriosSeulement {
        nouveauProprio = _nouveauProprio;
    }
    
    function confirmerNouveauProprio() public {
        require ( msg.sender == nouveauProprio );
        emit changementProprio ( proprio, nouveauProprio );
        proprio = nouveauProprio;
        delete nouveauProprio;
    }
}
