"use strict";

/**
 * This is a Node.JS application to register a new manufacturer on the network.
 */

const fs = require("fs");
const yaml = require("js-yaml");
const { Wallet, Gateway } = require("fabric-network");
let gateway;
let wallet;
let fabricUserName;
let connectionProfile;

//updateShipment(ctx, buyerCRN, drugName, transporterCRN)
async function main(nameOfOrg, buyerCRN, drugName, transporterCRN) {
  try {
    const pharmanetContract = await getContractInstance(nameOfOrg);

    console.log(".....Updating  a Shipment");
    const updateShipmentBuffer = await pharmanetContract.submitTransaction(
      "updateShipment",
      buyerCRN,
      drugName,
      transporterCRN
    );

    // process response
    console.log(".....Processing Shipment Transaction Response \n\n");
    let newUpdatedShipment = JSON.parse(updateShipmentBuffer.toString());
    console.log(newUpdatedShipment);
    console.log("\n\n.....Register New Updated Shipment Transaction Complete!");
    return newUpdatedShipment;
  } catch (error) {
    console.log(`\n\n ${error} \n\n`);
    throw new Error(error);
  } finally {
    // Disconnect from the fabric gateway
    console.log(".....Disconnecting from Fabric Gateway");
    gateway.disconnect();
  }
}

async function getContractInstance(nameOfOrg) {
  // A gateway defines which peer is used to access Fabric network
  // It uses a common connection profile (CCP) to connect to a Fabric Peer
  // A CCP is defined manually in file connection-profile-mhrd.yaml
  gateway = new Gateway();

  if (nameOfOrg === "manufacturer") {
    // A wallet is where the credentials to be used for this transaction exist
    // Credentials for user MHRD_ADMIN was initially added to this wallet.
    wallet = await Wallet.newFilesystemWallet("./identity/manufacturer");

    // What is the username of this Client user accessing the network?
    fabricUserName = "MANUFACTURER_ADMIN";

    // Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
    connectionProfile = yaml.safeLoad(fs.readFileSync("./connection-profile-manufacturer.yaml", "utf8"));
  } else if (nameOfOrg === "distributor") {
    // A wallet is where the credentials to be used for this transaction exist
    // Credentials for user MHRD_ADMIN was initially added to this wallet.
    wallet = await Wallet.newFilesystemWallet("./identity/distributor");

    // What is the username of this Client user accessing the network?
    fabricUserName = "DISTRIBUTOR_ADMIN";

    // Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
    connectionProfile = yaml.safeLoad(fs.readFileSync("./connection-profile-distributor.yaml", "utf8"));
  } else if (nameOfOrg === "transporter") {
    // A wallet is where the credentials to be used for this transaction exist
    // Credentials for user MHRD_ADMIN was initially added to this wallet.
    wallet = await Wallet.newFilesystemWallet("./identity/transporter");

    // What is the username of this Client user accessing the network?
    fabricUserName = "TRANSPORTER_ADMIN";

    // Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
    connectionProfile = yaml.safeLoad(fs.readFileSync("./connection-profile-transporter.yaml", "utf8"));
  } else if (nameOfOrg === "retailer") {
    // A wallet is where the credentials to be used for this transaction exist
    // Credentials for user MHRD_ADMIN was initially added to this wallet.
    wallet = await Wallet.newFilesystemWallet("./identity/retailer");

    // What is the username of this Client user accessing the network?
    fabricUserName = "RETAILER_ADMIN";

    // Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
    connectionProfile = yaml.safeLoad(fs.readFileSync("./connection-profile-retailer.yaml", "utf8"));
  } else if (nameOfOrg === "consumer") {
    // A wallet is where the credentials to be used for this transaction exist
    // Credentials for user MHRD_ADMIN was initially added to this wallet.
    wallet = await Wallet.newFilesystemWallet("./identity/consumer");

    // What is the username of this Client user accessing the network?
    fabricUserName = "CONSUMER_ADMIN";

    // Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
    connectionProfile = yaml.safeLoad(fs.readFileSync("./connection-profile-consumer.yaml", "utf8"));
  }

  // Set connection options; identity and wallet
  let connectionOptions = {
    wallet: wallet,
    identity: fabricUserName,
    discovery: { enabled: false, asLocalhost: true },
  };

  // Connect to gateway using specified parameters
  console.log(".....Connecting to Fabric Gateway");
  await gateway.connect(connectionProfile, connectionOptions);

  // Access certification channel
  console.log(".....Connecting to channel - pharmanet");
  const channel = await gateway.getNetwork("pharmanet");

  // Get instance of deployed Certnet contract
  // @param Name of chaincode
  // @param Name of smart contract
  console.log(".....Connecting to Certnet Smart Contract");
  return channel.getContract("pharmanet", "org.pharma-network.pharmanet");
}

module.exports.execute = main;
//"registerCompany",companyCRN, companyName, location, organisationRole;
