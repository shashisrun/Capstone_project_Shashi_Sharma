#Generate Crypto Materials
export PATH=${PWD}/../bin:$PATH
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-manufacturer.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-distributor.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-retailer.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-transporter.yaml --output="organizations"
cryptogen generate --config=./organizations/cryptogen/crypto-config-consumer.yaml --output="organizations"

#Generate Genesis Block Artifact
export FABRIC_CFG_PATH=${PWD}/configtx

configtxgen -profile PharmaOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

#Start Docker Network
export IMAGE_TAG=latest

docker-compose -f docker/docker-compose-pharmanet.yaml -f docker/docker-compose-ca.yaml up -d

sleep 10

#Generate Channel Creation Artifact 
configtxgen -profile PharmaChannel -outputCreateChannelTx ./channel-artifacts/pharmanet.tx -channelID pharmanet

#Create Channel from Peer0 of manufacturer
export FABRIC_CFG_PATH=$PWD/../config/
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/pharmachannel.net/orderers/orderer.pharmachannel.net/msp/tlscacerts/tlsca.pharmachannel.net-cert.pem
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="manufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/peers/peer0.manufacturer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel create -o localhost:7050 -c pharmanet --ordererTLSHostnameOverride orderer.pharmachannel.net -f ./channel-artifacts/pharmanet.tx --outputBlock "./channel-artifacts/pharmanet.block" --tls --cafile $ORDERER_CA

#join Channel for Peer0 of manufacturer
export BLOCKFILE="./channel-artifacts/pharmanet.block"
peer channel join -b $BLOCKFILE

#Join Channel for Peer1 of manufacturer
export CORE_PEER_ADDRESS=localhost:8051
peer channel join -b $BLOCKFILE

#Join Channel for Peer0 of distributor
export CORE_PEER_LOCALMSPID="distributorMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/peers/peer0.distributor.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/users/Admin@distributor.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:9051 
peer channel join -b $BLOCKFILE

#Join Channel for Peer1 of distributor
export CORE_PEER_ADDRESS=localhost:10051
peer channel join -b $BLOCKFILE

#Join Channel for Peer0 of retailer
export CORE_PEER_LOCALMSPID="retailerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/peers/peer0.retailer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/users/Admin@retailer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:11051
peer channel join -b $BLOCKFILE

#Join Channel for Peer1 of retailer
export CORE_PEER_ADDRESS=localhost:12051
peer channel join -b $BLOCKFILE


#Join Channel for Peer0 of transporter
export CORE_PEER_LOCALMSPID="transporterMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/peers/peer0.transporter.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/users/Admin@transporter.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:13051
peer channel join -b $BLOCKFILE

#Join Channel for Peer1 of transporter
export CORE_PEER_ADDRESS=localhost:14051
peer channel join -b $BLOCKFILE

#Join Channel for Peer0 of consumer
export CORE_PEER_LOCALMSPID="consumerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/peers/peer0.consumer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/users/Admin@consumer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:15051
peer channel join -b $BLOCKFILE

#Join Channel for Peer1 of consumer
export CORE_PEER_ADDRESS=localhost:16051
peer channel join -b $BLOCKFILE



#Update channel config to define anchor peer for Peer0 of each organisation

docker exec -it cli /bin/bash 

#manufacturer

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/pharmachannel.net/orderers/orderer.pharmachannel.net/msp/tlscacerts/tlsca.pharmachannel.net-cert.pem
export CORE_PEER_LOCALMSPID="manufacturerMSP"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/peers/peer0.manufacturer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.pharmachannel.net:7051
peer channel fetch config config_block.pb -o orderer.pharmachannel.net:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net -c pharmanet --tls --cafile $ORDERER_CA

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >"${CORE_PEER_LOCALMSPID}config.json"
export HOST="peer0.manufacturer.pharmachannel.net"
export PORT=7051
jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json

configtxlator proto_encode --input "${CORE_PEER_LOCALMSPID}config.json" --type common.Config >original_config.pb
configtxlator proto_encode --input "${CORE_PEER_LOCALMSPID}modified_config.json" --type common.Config >modified_config.pb
configtxlator compute_update --channel_id "pharmanet" --original original_config.pb --updated modified_config.pb >config_update.pb
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"pharmanet", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"${CORE_PEER_LOCALMSPID}anchors.tx"

peer channel update -o orderer.pharmachannel.net:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net -c pharmanet -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA

echo 'Exiting'

exit

#Package chaincode
 export CHANNEL_NAME=pharmanet
 export CC_NAME=pharmanet
 export CC_SRC_PATH=../chaincode
 export CC_RUNTIME_LANGUAGE=node
 export CC_VERSION=1.0
 export CC_SEQUENCE=1
 export FABRIC_CFG_PATH=$PWD/../config/
 peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION}

#install On Peer0 of manufacturer
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/pharmachannel.net/orderers/orderer.pharmachannel.net/msp/tlscacerts/tlsca.pharmachannel.net-cert.pem
export CORE_PEER_LOCALMSPID="manufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/peers/peer0.manufacturer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#install On Peer1 of manufacturer
export CORE_PEER_ADDRESS=localhost:8051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#install On Peer0 of distributor
export CORE_PEER_LOCALMSPID="distributorMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/peers/peer0.distributor.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/users/Admin@distributor.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#install On Peer1 of distributor
export CORE_PEER_ADDRESS=localhost:10051
peer lifecycle chaincode install ${CC_NAME}.tar.gz


#install On Peer0 of retailer
export CORE_PEER_LOCALMSPID="retailerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/peers/peer0.retailer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/users/Admin@retailer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:11051
peer lifecycle chaincode install ${CC_NAME}.tar.gz
      
#install On Peer1 of retailer      
export CORE_PEER_ADDRESS=localhost:12051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#install On Peer0 of transporter
export CORE_PEER_LOCALMSPID="transporterMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/peers/peer0.transporter.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/users/Admin@transporter.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:13051
peer lifecycle chaincode install ${CC_NAME}.tar.gz
      
#install On Peer1 of transporter      
export CORE_PEER_ADDRESS=localhost:14051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#install On Peer0 of consumer
export CORE_PEER_LOCALMSPID="consumerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/peers/peer0.consumer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/users/Admin@consumer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:15051
peer lifecycle chaincode install ${CC_NAME}.tar.gz
      
 #install On Peer1 of consumer     
export CORE_PEER_ADDRESS=localhost:16051
peer lifecycle chaincode install ${CC_NAME}.tar.gz

#Query  
peer lifecycle chaincode queryinstalled
export PACKAGE_ID=pharmanet_1.0:622247669947483591c9fc276a93c756c13a13429d0bc6705acd1b87a6b82cd7

#Approve for manufacturer Organisation
export CORE_PEER_LOCALMSPID="manufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/peers/peer0.manufacturer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/users/Admin@manufacturer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}

#Approve for distributor Organisation
export CORE_PEER_LOCALMSPID="distributorMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/peers/peer0.distributor.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/users/Admin@distributor.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}

#Approve for transporter
export CORE_PEER_LOCALMSPID="retailerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/peers/peer0.retailer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/users/Admin@retailer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:11051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}

#Approve for retailer
export CORE_PEER_LOCALMSPID="transporterMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/peers/peer0.transporter.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/users/Admin@transporter.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:13051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}

#Approve for consumer
export CORE_PEER_LOCALMSPID="consumerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/peers/peer0.consumer.pharmachannel.net/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/users/Admin@consumer.pharmachannel.net/msp
export CORE_PEER_ADDRESS=localhost:15051
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}

#Check Commit Readiness
peer lifecycle chaincode checkcommitreadiness --channelID pharmanet --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json

#Commit
 peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.pharmachannel.net --tls --cafile $ORDERER_CA --channelID pharmanet --name ${CC_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/manufacturer.pharmachannel.net/peers/peer0.manufacturer.pharmachannel.net/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/distributor.pharmachannel.net/peers/peer0.distributor.pharmachannel.net/tls/ca.crt --peerAddresses localhost:11051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/retailer.pharmachannel.net/peers/peer0.retailer.pharmachannel.net/tls/ca.crt --peerAddresses localhost:13051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/transporter.pharmachannel.net/peers/peer0.transporter.pharmachannel.net/tls/ca.crt --peerAddresses localhost:15051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/consumer.pharmachannel.net/peers/peer0.consumer.pharmachannel.net/tls/ca.crt --version ${CC_VERSION} --sequence ${CC_SEQUENCE}
    
 #Query Committed
 peer lifecycle chaincode querycommitted --channelID pharmanet --name ${CC_NAME}