const { expect } = require("chai");
const {ethers} = require('hardhat');


describe('Test Contract', () => {
    beforeEach(async () => {
      const XBettingUC = await ethers.getContractFactory('XBettingUC');
      [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

      xBettingUC = await XBettingUC.deploy(
        owner.address,
        owner.address
        );  
    });

    describe('Match', () => {
        it('should flow add match correctly', async () => {
       
         await xBettingUC.connect(owner).addMatches([
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
            }
          ]);

          await xBettingUC.connect(owner).betting([
            {
                scoreOne : 2,
                scoreTwo : 3,
            },
            {
                scoreOne : 2,
                scoreTwo : 3,
            }
          ]);

          await xBettingUC.connect(addr1).betting([
            {
                scoreOne : 2,
                scoreTwo : 2,
            },
            {
                scoreOne : 2,
                scoreTwo : 3,
            }
          ]);

          const destPortAddr = "0x1234567890abcdef1234567890abcdef12345678";
          const channelId = "channel-16";
          const channelIdBytes = ethers.encodeBytes32String(channelId);
          const timeoutSeconds = 3600;

          await xBettingUC.reveal(destPortAddr,channelIdBytes,timeoutSeconds);

          let matches = await xBettingUC.getMatches();
          console.log(matches)

          let matches1 = await xBettingUC.getLeaderboard();
          console.log(matches1)
    
        });
    });
    
    
});
