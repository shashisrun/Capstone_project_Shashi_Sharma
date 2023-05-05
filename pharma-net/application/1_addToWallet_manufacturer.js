"use strict";

/**
 * This is a Node.JS module to load a user's Identity to his wallet.
 * This Identity will be used to sign transactions initiated by this user.
 * Defaults:
 *  User Name: MANUFACTURER_ADMIN
 *  User Organization: MANUFACTURER
 *  User Role: Admin
 *
 */

const fs = require("fs"); // FileSystem Library
const { Wallets } = require("fabric-network"); // Wallet Library provided by Fabric
const path = require("path"); // Support library to build filesystem paths in NodeJs


async function main(certificatePath, privateKeyPath) {
  // Main try/catch block
  try {
    // A wallet is a filesystem path that stores a collection of Identities
    const wallet = await Wallets.newFileSystemWallet("./identity/manufacturer");
    // Fetch the credentials from our previously generated Crypto Materials required to create this user's identity
    const certificate = fs.readFileSync(certificatePath).toString();
    // IMPORTANT: Change the private key name to the key generated on your computer
    const privatekey = fs.readFileSync(privateKeyPath).toString();

    // Load credentials into wallet
    const identityLabel = "MANUFACTURER_ADMIN";
    const identity = {
      credentials: {
        certificate: certificate,
        privatekey: privatekey
      },
      mspId: 'manufacturerMSP',
      type: 'X.509'
    }

    await wallet.put(identityLabel, identity);
  } catch (error) {
    console.log(`Error adding to wallet. ${error}`);
    console.log(error.stack);
    throw new Error(error);
  }
}

main(
   path.resolve(__dirname, "../network/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp/signcerts/Admin@manufacturer.pharmachannel.net-cert.pem"),
   path.resolve(__dirname, "../network/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp/keystore/priv_sk")
).then(() => {
  console.log("Manufacturer identity added to wallet.");
});

module.exports.execute = main;
