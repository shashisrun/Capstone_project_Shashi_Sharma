"use strict";

/**
 * This is a Node.JS module to load a user's Identity to his wallet.
 * This Identity will be used to sign transactions initiated by this user.
 * Defaults:
 *  User Name: CONSUMER_ADMIN
 *  User Organization: CONSUMER
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
    const wallet = await Wallets.newFileSystemWallet("./identity/consumer");
    // Fetch the credentials from our previously generated Crypto Materials required to create this user's identity
    const certificate = fs.readFileSync(certificatePath).toString();
    // IMPORTANT: Change the private key name to the key generated on your computer
    const privatekey = fs.readFileSync(privateKeyPath).toString();

    // Load credentials into wallet
    const identityLabel = "CONSUMER_ADMIN";
    const identity = {
      credentials: {
        certificate: certificate,
        privatekey: privatekey
      },
      mspId: 'consumerMSP',
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
  path.resolve(__dirname, "../network/organizations/peerOrganizations/consumer.pharmachannel.net/users/Admin@consumer.pharmachannel.net/msp/signcerts/Admin@consumer.pharmachannel.net-cert.pem"),
  path.resolve(__dirname, "../network/organizations/peerOrganizations/consumer.pharmachannel.net/users/Admin@consumer.pharmachannel.net/msp/keystore/priv_sk")
).then(() => {
  console.log("Consumer identity added to wallet.");
});

module.exports.execute = main;
