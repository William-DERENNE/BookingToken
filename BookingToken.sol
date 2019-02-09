pragma solidity ^0.5.3;
import "browser/Acquis.sol";
import "browser/IERC20.sol";
import "browser/CheckERC165.sol";


/* BookingToken ERC20, ERC223, ERC165 ( interface 0xf771218b ) avec des morceaux de BTU Token.
 
  - Gelable (Token ET comptes clients de façon individuelle ainsi que blocage des achats en Eth de tokens mintés).
  - Stackable.
  - Mintable AVEC mintage sur Stacking.
  - Achetable directement en Ether: -SOIT transféré de la somme totale de Tokens ('initialSupply')
                                    -SOIT minté
  - Fonction d'AIRDROP intégrée.
 
 
                  Un petit mot et une pensée pour les équipes de tout Kryptosphère France : 
 
                                         - LA CLAQUE AVEC ELAN ! -
 
 

                                                                                      William DERENNE
*/
 
 
interface tokenRecipient { function receiveApproval ( address _from, uint256 _value, address _token, bytes calldata _extraData ) external; }

contract BookingToken is Acquis, IERC20, CheckERC165 {
                    using SafeMath for uint8;
    
    string public name;                                 // ERC20
    string public symbol;                               // ERC20
    
    uint8 public decimals;                              // ERC20
    uint256 public totalSupply;                         // ERC20
    uint256 public totalEthInWei;                       // ERC20
    uint256 public unitsOneEthCanBuy;                   // Nombre de tokens qu'1 Ether peut acheter.
    
    bool public bloquerToken;
    bool public bloquerAchatETH;
    bool public bloquerAchatMint;
    
    struct Reservation {                                // BTU Token
        address     provider;
        address     booker;
        uint        amount;
        uint        commission;
    }

    address[] public adrClients;
    
    mapping ( address => uint256 ) public balanceOf;                                // ERC20
    mapping ( address => mapping ( address => uint256 ) ) public allowance;         // ERC20
    mapping ( address => bool ) public comptesGeles;
    mapping ( uint => Reservation ) public reservations;                        // BTU Token

    event Achat ( address adrClient, uint256 montantETH, uint montantTOKEN );
    event AchatMinte ( address adrClient, uint256 montantETH, uint256 montantTOKEN );
    event Transfer ( address indexed from, address indexed to, uint256 value );     // ERC20
    event Burn ( address indexed from, uint256 value );
    event Stackage ( address adrClient, uint256 montant );
    event StackageMinte ( address adrClient, uint256 montant );
    event CompteGele ( address adrClient, bool gele );
    event Airdrop ( address porteur, uint256 somme );

    modifier ON {
        require ( bloquerToken == false );
        _;
    }
    
    modifier AchatEthON {
        require ( bloquerAchatETH == false );
        _;
    }
    
    modifier AchatMintON {
        require ( bloquerAchatMint == false );
        _;
    }
    
    modifier Secu {
        require ( msg.value > 0 && msg.sender != address ( 0x0 ) );
        _;
    }


        /**
         * Constrcteur.
         *
         * Initialise le contrat en transférant la 'totalSupply' au compte 'proprio'
         * tel que défini dans 'Acquis.sol' dont PzToken hérite.
         */
            constructor ( uint256 _initialSupply, uint8 _decimals, string memory _tokenName, string memory _tokenSymbol ) public {
                
                bloquerToken = false;                       // Allume le Token.
                proprio = msg.sender;                       // Propriétarisation.
                decimals = _decimals;                       // Création des unités du Token.
                totalSupply = _initialSupply * 10 ** uint256 ( _decimals ); // Ajoute les décimales aux unités du Token.
                balanceOf[proprio] = totalSupply;                           // Transfert de tous les Tokens ainsi créés au compte 'proprio'.
                name = _tokenName;                                          // Nom complet du Token.
                symbol = _tokenSymbol;                                      // Symbole du Token.
                totalEthInWei = address ( this ).balance;
                
                supportedInterfaces[    // ERC165
                    this.name.selector ^
                    this.symbol.selector ^
                    this.totalSupply.selector ^
                    this.allowance.selector ^
                    this.comptesGeles.selector ^
                    this.reservations.selector ^
                    this.totalEthInWei.selector ^
                    this.balanceOf.selector ^
                    this.bloquerToken.selector ^
                    this.bloquerAchatETH.selector ^
                    this.bloquerAchatMint.selector ^
                    this.adrClients.selector ^
                    bytes4(keccak256("bloquerLeToken("))^
                    bytes4(keccak256("debloquerLeToken("))^
                    bytes4(keccak256("gelerDegelerCompte(address _adrClient,bool _gele"))^
                    bytes4(keccak256("bloquerDebloquerAchatETH(bool _blocage"))^
                    bytes4(keccak256("bloquerDebloquerAchatMinte(bool _blocage"))^
                    bytes4(keccak256("bloquerDebloquerAchatMinte(bool _blocage"))^
                    bytes4(keccak256("SetPrix(uint _unitsOneEthCanBuy"))^
                    bytes4(keccak256("airdrop(address[] memory _adrPorteurs, uint256[] memory _sommes, uint256 _sommeTotale"))^
                    bytes4(keccak256("stacker(address _adrClient, uint _pourcentage"))^
                    bytes4(keccak256("minterStack(address _adrClient, uint _pourcentage"))^
                    bytes4(keccak256("acheterMint("))^
                    bytes4(keccak256("escrowAmount(uint availabilityId,address booker,address provider,uint amount,uint commission"))^
                    bytes4(keccak256("escrowBackToAccount(uint availabilityId,address payTo"))^
                    bytes4(keccak256("escrowResolveDispute(uint availabilityId"))^
                    bytes4(keccak256("listReservationsDetails (uint availabilityNumber"))^
                    this.transfer.selector ^
                    this.transferFrom.selector ^
                    this.approve.selector ^
                    this.approveAndCall.selector ^
                    this.burn.selector ^
                    this.burnFrom.selector ^
                    this.mintToken.selector
                ] = true;
            }

    
    function getThisInterface() public pure returns ( bytes4 ) {    // ERC165
        return bytes4 ( 
                    this.name.selector ^
                    this.symbol.selector ^
                    this.totalSupply.selector ^
                    this.allowance.selector ^
                    this.comptesGeles.selector ^
                    this.reservations.selector ^
                    this.totalEthInWei.selector ^
                    this.balanceOf.selector ^
                    this.bloquerToken.selector ^
                    this.bloquerAchatETH.selector ^
                    this.bloquerAchatMint.selector ^
                    this.adrClients.selector ^
                    bytes4(keccak256("bloquerLeToken("))^
                    bytes4(keccak256("debloquerLeToken("))^
                    bytes4(keccak256("gelerDegelerCompte(address _adrClient,bool _gele"))^
                    bytes4(keccak256("bloquerDebloquerAchatETH(bool _blocage"))^
                    bytes4(keccak256("bloquerDebloquerAchatMinte(bool _blocage"))^
                    bytes4(keccak256("bloquerDebloquerAchatMinte(bool _blocage"))^
                    bytes4(keccak256("SetPrix(uint _unitsOneEthCanBuy"))^
                    bytes4(keccak256("airdrop(address[] memory _adrPorteurs, uint256[] memory _sommes, uint256 _sommeTotale"))^
                    bytes4(keccak256("stacker(address _adrClient, uint _pourcentage"))^
                    bytes4(keccak256("minterStack(address _adrClient, uint _pourcentage"))^
                    bytes4(keccak256("acheterMint("))^
                    bytes4(keccak256("escrowAmount(uint availabilityId,address booker,address provider,uint amount,uint commission"))^
                    bytes4(keccak256("escrowBackToAccount(uint availabilityId,address payTo"))^
                    bytes4(keccak256("escrowResolveDispute(uint availabilityId"))^
                    bytes4(keccak256("listReservationsDetails (uint availabilityNumber"))^
                    this.transfer.selector ^
                    this.transferFrom.selector ^
                    this.approve.selector ^
                    this.approveAndCall.selector ^
                    this.burn.selector ^
                    this.burnFrom.selector ^
                    this.mintToken.selector
        );
    }
    
    /**
     * Fonctions de Blocage et de Déblocage du Token.
     */
    function bloquerLeToken() public propriosSeulement {
        bloquerToken = true;
    }
    
    function debloquerLeToken() public propriosSeulement {
        bloquerToken = false;
    }

    /**
     * Permet le blocage et le déblocage d'un compte en Tokens.
     * 
     * @param _adrClient Adresse du compte client à geler/dégeler
     * @param _gele boléen : true = gelé; false = dégelé (fonctionnement normal)
     */
    function gelerDegelerCompte ( address _adrClient, bool _gele ) public propriosSeulement {
        comptesGeles[_adrClient] = _gele;
        
        emit CompteGele ( _adrClient, _gele );
    }

    /**
     * Permet le blocage/déblocage des achats de tokens en Ether
     * par la function fallback
     * @param _blocage : true = bloqué; false = débloqué (fonctionnement normal)
     */
    function bloquerDebloquerAchatETH ( bool _blocage ) public propriosSeulement {
        bloquerAchatETH = _blocage;
    }

    /**
     * Permet le blocage/déblocage des achats MINTéS de tokens en Ether
     * par la function fallback
     * @param _blocage : true = bloqué; false = débloqué (fonctionnement normal)
     */
    function bloquerDebloquerAchatMinte ( bool _blocage ) public propriosSeulement {
        bloquerAchatMint = _blocage;
    }

    /**
     * Transfert interne, appelable de ce contrat seuement.
     */
    function _transfer ( address _from, address _to, uint _value ) internal ON {
        require ( address ( _to ) != address ( 0x0 ) );
        require ( balanceOf[_from] >= _value );
        require ( balanceOf[_to] + _value > balanceOf[_to] );
        require ( ! comptesGeles[_from] && ! comptesGeles[_to] );           // Vérification des comptes bloqués
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer ( _from, _to, _value );
        assert ( balanceOf[_from] + balanceOf[_to] == previousBalances );
    }

    /** ERC20
     * Transfert de tokens.
     * Envoie `_value` tokens à `_to` depuis le wallet appelant. Doit être PUBLIC.
     *
     * @param _to L'adress du receveur
     * @param _value Le montant à envoyer
     */
    function transfer ( address _to, uint256 _value ) public ON returns ( bool ) {
        _transfer ( msg.sender, _to, _value );
        
        return true;
    }

    /** ERC20
     * Transfert des tokens depuis l'adresse 'from'.
     * Envoie '_value' Tokens à `_to` au nom de `_from`.
     *
     * @param _from L'adress du dépenseur
     * @param _to L'adresse du récipiendaire
     * @param _value Le montant à envoyer
     */
    function transferFrom ( address _from, address _to, uint256 _value ) public returns ( bool success ) {
        require ( _value <= allowance[_from][msg.sender] );     // Check allowance
        
        allowance[_from][msg.sender] -= _value;
        _transfer ( _from, _to, _value );
        
        return true;
    }

    /** ERC223
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve ( address _spender, uint256 _value ) public propriosSeulement returns ( bool success ) {
        allowance[proprio][_spender] = _value;
        
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall ( address _spender, uint256 _value, bytes memory _extraData ) public propriosSeulement returns ( bool success ) {
        tokenRecipient spender = tokenRecipient ( _spender );
        if ( approve ( _spender, _value ) ) {
            spender.receiveApproval ( proprio, _value, address ( this ), _extraData );
            
            return true;
        }
    }

    /**
     * Détruit des Tokens.
     * Brûle `_value` Tokens du système irréversiblement.
     *
     * @param _value Le nombre de Token à brûler
     */
    function burn ( uint256 _value ) public propriosSeulement returns ( bool success ) {
        require ( balanceOf[msg.sender] >= _value );    // Check if the sender has enough
        
        balanceOf[msg.sender] -= _value;                // Subtract from the sender
        totalSupply -= _value;                          // Updates totalSupply
        
        emit Burn ( msg.sender, _value );
        return true;
    }

    /**
     * Détruit des Tokens depuis une l'adress 'from'.
     * Brûle `_value` Tokens du système irréversiblement a l'adresse `_from`.
     *
     * @param _from L'adresse à laquelle brûler des Tokens
     * @param _value Le nombre de Tokens à brûler
     */
    function burnFrom ( address _from, uint256 _value ) public propriosSeulement returns (bool success) {
        require ( balanceOf[_from] >= _value );                // Check if the targeted balance is enough
        
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        totalSupply -= _value;                              // Update totalSupply
        
        emit Burn ( _from, _value );
        return true;
    }
    
    /**
     * Définie le nombre de Tokens qu'un Ether peut acheter.
     * 
     * @param _unitsOneEthCanBuy Le nombre de Tokens qu'un Ether peut acheter en wei.
     */
    function SetPrix ( uint _unitsOneEthCanBuy ) public propriosSeulement {
        unitsOneEthCanBuy = _unitsOneEthCanBuy;
    }

    /**
     * Crée `mintedAmount` Tokens et les envoie à `target`.
     * 
     * @param _target Adresse de réception des Tokens
     * @param _mintedAmount Le montant en Tokens à recevoir
     */
    function mintToken ( address _target, uint256 _mintedAmount ) public propriosSeulement {
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        
        emit Transfer ( address ( 0 ), address ( this ), _mintedAmount );
        emit Transfer ( address ( this ), _target, _mintedAmount );
    }

    /**
     * mintToken() INTERNE
     * 
     * @param _target Adresse de réception des Tokens
     * @param _mintedAmount Le montant en Tokens à recevoir
     */
    function _mintToken ( address _target, uint256 _mintedAmount ) internal {
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        
        emit Transfer ( address ( 0 ), address ( this ), _mintedAmount );
        emit Transfer ( address ( this ), _target, _mintedAmount );
    }

    /**
     * Fonction d'Airdrop automatisée.
     * 
     * @param _adrPorteurs : tableau des adresses ETH des receveurs de tokens.
     * @param _sommes : tableau des sommes attribuées à chaque adresse de _adrPorteurs.
     * @param _sommeTotale : Somme totale airdropée.
     */
    function airdrop ( address[] memory _adrPorteurs, uint256[] memory _sommes, uint256 _sommeTotale ) public propriosSeulement {
        require ( _sommeTotale >= _adrPorteurs.length );        // Sécurisation : 1 wei minimum par transaction.
        require ( address ( this ).balance >= _sommeTotale );
        
        for ( uint _i = 0; _i >= adrClients.length; _i ++ ) {
            address _porteur = _adrPorteurs[_i];
            balanceOf[_porteur] += _sommes[_i];
            
            emit Airdrop ( _porteur, _sommes[_i] );
        }
    }

    /**
     * Donne _'pourcentage'% en Tokens au compte '_adrClient' selon son solde actuel, - débités de 'totalSupply'
     * 
     * @param _adrClient Adresse qui reçoit les Tokens
     * @param _pourcentage Pourcentage de Tokens à transférer à '_adrClient'
     */
    function stacker ( address _adrClient, uint _pourcentage ) public propriosSeulement {
        uint _balancePrecedente = balanceOf[_adrClient];
        uint _montant = ( _balancePrecedente / 100 ) * _pourcentage;
        
        balanceOf[_adrClient] += _montant;
        balanceOf[proprio] -= _montant;
        
        emit Stackage ( _adrClient, _montant );
    }

    /**
     * Donne _'pourcentage'% en Tokens au compte '_adrClient' selon son solde actuel, - mintés -
     * 
     * @param _adrClient Adresse qui reçoit les Tokens
     * @param _pourcentage Pourcentage de Tokens à transférer à '__adrClient'
     */
    function minterStack ( address _adrClient, uint _pourcentage ) public propriosSeulement {
        uint _balancePrecedente = balanceOf[_adrClient];
        uint _montant = ( _balancePrecedente / 100 ) * _pourcentage;
        
        emit StackageMinte ( _adrClient, _montant );
        
        mintToken ( _adrClient, _montant );
    }

    /** BTU Token
     * 
     */
    function escrowAmount(uint availabilityId, address booker, address provider, uint amount, uint commission) public returns (bool response) {
        if ( balanceOf[booker] < amount ) {
            return false;
        }
        reservations[availabilityId] = Reservation ( provider, booker, amount, commission );
        balanceOf[booker] -= amount;
        
        return true;
    }

    /** BTU Token
     * 
     */        
    function escrowBackToAccount ( uint availabilityId, address payTo ) public returns ( bool response ) {
        balanceOf[payTo] += reservations[availabilityId].amount;
        reservations[availabilityId].amount = 0;
        reservations[availabilityId].commission = 0;
        
        return true;
    }
        
    /** BTU Token
     * 
     */    
    function escrowResolveDispute( uint availabilityId ) public returns ( bool response ) {
        balanceOf[reservations[availabilityId].provider] += reservations[availabilityId].amount - reservations[availabilityId].commission;
        balanceOf[reservations[availabilityId].booker] += reservations[availabilityId].commission;
        reservations[availabilityId].commission = 0;
        reservations[availabilityId].amount = 0;
    
        return true;
    }
    
    /** BTU Token
     * 
     */        
    function listReservationsDetails ( uint availabilityNumber ) public view returns ( address, address, uint, uint ) {
        address                 provider;
        address                 booker;
        uint                    amount;
        uint                    commission;
    
        provider = reservations[availabilityNumber].provider;
        booker = reservations[availabilityNumber].booker;
        amount = reservations[availabilityNumber].amount;
        commission = reservations[availabilityNumber].commission;
        
        return (provider, booker, amount, commission);
    }

    /**
     * -Mint- un montant en tokens correspondant à la somme en Eth envoyée
     * au prix de 'unitsOneEthCanBuy'.
     */
    function acheterMint() external payable Secu ON AchatMintON {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 _amount = msg.value * unitsOneEthCanBuy;

        _mintToken ( msg.sender, _amount );
        
        emit AchatMinte ( msg.sender, msg.value, _amount );
    }

    /** ERC223
     * Achat de Tokens en Eth au prix de 'unitsOneEthCanBuy'.
     */
    function() external payable Secu ON AchatEthON {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 _amount = msg.value * unitsOneEthCanBuy;
        require(balanceOf[proprio] >= _amount);

        balanceOf[proprio] -= _amount;
        balanceOf[msg.sender] += _amount;
        proprio.transfer ( msg.value );                               

        emit Transfer ( proprio, msg.sender, _amount ); // Broadcast a message to the blockchain
    }
}
