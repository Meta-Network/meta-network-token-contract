//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";

interface IMintable {
    function mint(address to, uint256 amount) external;
}

contract MultisigMinter {
    bytes32 public DOMAIN_SEPARATOR;

    uint256 nonce = 0;
    uint256 threshold = 0;

    mapping(address => bool) public isAdmin;

    event TokenMinted(
        address token,
        address to,
        uint256 amount,
        address[] signer
    );

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    // keccak256("Mint(address token,address to,uint256 amount,uint256 nonce)");
    bytes32 public constant MINT_TYPEHASH =
        keccak256(
            "Mint(address token,address to,uint256 amount,uint256 nonce)"
        );

    constructor(address[] memory admins, uint256 _threshold) {
        for (uint256 i = 0; i < admins.length; i++) {
            address _admin = admins[i];
            isAdmin[_admin] = true;
        }
        // Validate that threshold is smaller than number of added owners.
        require(
            _threshold <= admins.length,
            "Threshold cannot exceed owner count"
        );
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "Threshold needs to be greater than 0");
        threshold = _threshold;
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MultisigMinter")),
                keccak256(bytes("1")),
                _chainId,
                address(this)
            )
        );
    }

    function mint(
        address mintable,
        address to,
        uint256 amount,
        Signature[] memory signatures
    ) external {
        // There has to be at least one Safe owner.
        require(
            threshold <= signatures.length,
            "signatures length needs to be greater or equal than Threshold"
        );
        address[] memory signers = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes32 digest =
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(
                            abi.encode(
                                MINT_TYPEHASH,
                                mintable,
                                to,
                                amount,
                                nonce++
                            )
                        )
                    )
                );
            address recoveredAddress =
                ecrecover(
                    digest,
                    signatures[i].v,
                    signatures[i].r,
                    signatures[i].s
                );
            signers[i] = recoveredAddress;
            require(
                recoveredAddress != address(0) && isAdmin[recoveredAddress],
                "MultisigMinter: INVALID_SIGNATURE"
            );
        }
        // Signatures Checked, ready to mint
        IMintable(mintable).mint(to, amount);
        emit TokenMinted(mintable, to, amount, signers);
    }
}
