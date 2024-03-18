// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const { getConfigPath } = require('./private/_helpers.js');
const { getIbcApp } = require('./private/_vibc-helpers.js');

async function main() {
    const accounts = await hre.ethers.getSigners();
    const config = require(getConfigPath());

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);

    // Send the packet
    // console.log(`Sending a packet via IBC to mint an NFT for ${recipient} related to vote from ${voterAddress}`);
    await ibcApp.connect(accounts[0]).addMatches([
        {
          teamOne:{
              name : "Pacers",
              logo : "https://seeklogo.com/images/I/indiana-pacers-logo-2A35FAB8C1-seeklogo.com.png"
          },
          teamTwo:{
              name : "Cavaliers",
              logo : "https://seeklogo.com/images/N/nba-cleveland-cavaliers-logo-EC287BF14E-seeklogo.com.png"
          },
          link: "https://www.youtube.com/watch?v=VaTWiSCH4TI",
          schedule : "Tuesday, 19 Maret 2024. 4:30 AM",
          scoreOne : 0,
          scoreTwo : 0,
          reveal : false,
      },
      {
          teamOne:{
              name : "76ers",
              logo : "https://seeklogo.com/images/P/philadelphia-76ers-logo-1B0F580BA2-seeklogo.com.png"
          },
          teamTwo:{
              name : "Heat",
              logo : "https://seeklogo.com/images/M/miami-heat-logo-6EB7EE737A-seeklogo.com.png"
          },
          link: "https://www.youtube.com/watch?v=ekA5nCJeWrk",
          schedule : "Tuesday, 19 Maret 2024. 5:30 AM",
          scoreOne : 0,
          scoreTwo : 0,
          reveal : false,
      },
      {
        teamOne:{
            name : "Jazz",
            logo : "https://seeklogo.com/images/U/utah-jazz-logo-D841C47B4D-seeklogo.com.png"
        },
        teamTwo:{
            name : "Timberwolves",
            logo : "https://seeklogo.com/images/M/minnesota-timberwolves-logo-B362F9482F-seeklogo.com.png"
        },
        link: "https://www.youtube.com/watch?v=ekA5nCJeWrk",
        schedule : "Tuesday, 19 Maret 2024. 6:30 AM",
        scoreOne : 0,
        scoreTwo : 0,
        reveal : false,
    },
    {
        teamOne:{
            name : "Kings",
            logo : "https://seeklogo.com/images/S/sacramento-kings-logo-EBB8B9D66E-seeklogo.com.png"
        },
        teamTwo:{
            name : "Grizzlies",
            logo : "https://seeklogo.com/images/M/memphis-grizzlies-logo-10817A022C-seeklogo.com.png"
        },
        link: "https://www.youtube.com/watch?v=ekA5nCJeWrk",
        schedule : "Tuesday, 19 Maret 2024. 7:30 AM",
        scoreOne : 0,
        scoreTwo : 0,
        reveal : false,
    }
    ]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});