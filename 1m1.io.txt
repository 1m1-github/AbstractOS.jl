import 'package:flutter/material.dart';
import 'success.dart';

class CVProviderModel extends ChangeNotifier {
  List<String> keywordList = [];
  List<String> keywords = [];

  bool isOpenSuggestionView = false;

  List<SuccessData> mainCvList = [];

  // 1M1
  static List<SuccessData> imiSuccesses = [
    const SuccessData(title: 'TA for Numerical Analysis', timestamp: 1051798846, tags: ['math', 'academics'], description: '''
  i got a job working as a TA (teaching assistant) for the Numerical Analysis course at the Humboldt Universität zu Berlin where i was studying math at the time.
  this course was mandatory for all students of mathematics. i myself had to still take it. i got the job over other candidates despite not having taken the course because my grades were (near) perfect.
  i corrected homework, helped students understand and at the end of the semester, i also submitted my own project earning me the credits for the course.
'''),
const SuccessData(title: 'languages', timestamp: 2532614400, tags: ['languages'], description: '''
  by living and growing up in over 10 countries, across continents and cultures, i have over my life time spoken 11 human languages, with at least basic fluency ~ some i have forgotten and still speak 7 human languages
  furthermore, i have coded in ca. 30 computer languages and i love learning new technologies 
  tip: i have found that to learn a language, one has to simply force oneself to use only that language plus body language ~ beginning with a word, your vocab will increase everyday and you will be fluent within half a year
  also, learn the word "opposite" in your target language, as it basically doubles your vocab (you know a word X, ask a local "opposite X?")
'''),
    const SuccessData(
        title: '2i2i.app',
        timestamp: 1632614400,
        tags: ['Algorand', 'blockchain', 'app', 'WebRTC', 'Flutter', 'dart', 'GCP', 'market', 'startup', 'Encode', 'award', '2i2i'],
        description: '''
new whitepaper: https://github.com/2i2i/whitepaper

2i2i is the idea that everyone has value

2i2i allows everyone to earn their value in coins

2i2i is market for your time right *now*
you have *something* to offer ~ the value of it is best measured in a market

share your link with the world and allow the world to offer coins for your time
if you like the offer, have a live video meeting

*
on-chain, any coin, private, scalable, zero credit-risk
*

* on-chain: runs on Algorand, super cheap, fast and safe
* any coin: any coin of any economic value or even coins of subjective value (e.g. NFTs) (rm)
* private: your meeting is end-2-end encrypted and peer-2-peer ~ even 2i2i does not see your data
* scalable: peer-2-peer meetings allow for an efficient network
* zero credit-risk: coins are locked in an autonomous (rm) smart contract ~ no one can steal them, not even 2i2i

its the uber of talking ~ giving everyone an income stream

=======
app to be released on Android and iOS
=======


further thoughts:
set the minimum support you want for your time and watch as the world bids higher or lower to show what your measured value is

you similarly can talk with whomever you want and give them support in coins
the more valueable it is for you to talk with them, the more you are willing to offer
there are people in the world that you might love to have a chat with who normally you would not have a chance to chat with
there are people that are extremely busy but have very valuable advice
is it worth for them to be on 2i2i ~ yes, of course, because they can transform their very high value into energy in the form of coins

money is an efficient storage of energy
imagine i expend energy by cleaning someone's garden
in exchange they give me money
then, maybe in ten years, i could exchange that money for someone cleaning my pool
so i exchanged money for energy
i had energy, i gave away energy and exchanged it for money
and then i exchanged my money for energy
and so the money was an as efficient as inflation storage for energy
and so, someone who is very busy but has valuable advice or is just valuable as a person
this person can exchange their value into coins and with those coins they buy whatever they want
point being, since 2i2i is a market, there will be people offering very high amounts for people of very high perceived value
hence, of course such a person is willing to take that ~ imagine a high celebrity ~ would such a person be willing to talk for 1 million USD per hour with a random fan
yes, of course, because they could also just talk for 30 seconds and earn 30/(60*60)*1 million USD = ca. 10'000 USD

everyone earns and helps others earn more
its the uber of talking ~ giving everyone an income stream
the fairest one ~ according to your market

roadmap
rm: currently only ALGO is supported ~ all coins coming soon
rm: currently the smart contract is controlled by 2i2i ~ after it will be controlled by a DAO ~ finally it will be autonomous


history
2i2i was created during a hackathon with encode in 2021 which ended with the first MVP.
2i2i was accepted into the encode accelerator in 2022 which ended in refined testnet dApp.
2i2i has received an Algorand foundation grant and will soon release the mainnet dApp.

'''),
    const SuccessData(title: 'Machine Learning based system to calculate microfinancing credit risk', timestamp: 1575158400, tags: [
      'ML',
      'AI',
      'credit risk',
      'julia',
      'CRO',
      'math',
      'finance',
    ], description: '''
implemented a Machine Learning system written in julia to evaluate individual (retail) credit risk given for micro financing.
The system combined all available data, including:
• financial history_provider taken from the users bank account (given user consent).
• behavioral data from the web app
• other credit risk models

the in-sample and out-sample (live data) result were quite precise.
evaluating statistics after changing parameters of the model showed results strongly inline with predicted results.
even though each individual is unique, the portfolio credit risk can be modeled powerfully using Machine Learning.
'''),
    const SuccessData(title: 'automated online lending system', timestamp: 1569888000, tags: ['GCP', 'app', 'javascript', 'vue', 'CTO', 'IT', 'finance'], description: '''
implemented a high performance GCP based infrastructure to run a fully automated micro financing system
• serverless backend, highly scalable and secure
• IT infrastructure based on GCP
• connected to a machine learning based credit risk model
• frontend written in vue: I wrote the first version, which was improved by frontend pros

The system itself was shutdown due to lack of funding even though the tech worked well
'''),
    const SuccessData(title: 'Quasi Monte Carlo with PCA implementation', timestamp: 1433116800, tags: ['Monte Carlo', 'julia', 'C#', 'math', 'PCA', 'Axpo'], description: '''
implemented a highly performant quasi monte carlo algorithm with PCA
• written in julia
• payout and diffusion equations were run time compiled from julia syntax allowing the user to evaluate any contract based
• C level speed
• in partnership with Axpo AG, Switzerland
'''),
    const SuccessData(title: 'web app using .NET', timestamp: 1451606400, tags: ['app', '.NET', 'C#', 'award', 'Axpo'], description: '''
together with another software engineer, we implemented a front end client-facing web app for Axpo AG, Switzerland.
this was a replacement for an existing app, which Axpo had asked me to improve. the original version had cost hundreds of thousands of Swiss Franks and several years to create.
the original app was extremely buggy, e.g. it needed a daily server restart.
instead of improving the existing app, i insisted and remade everything from scrath in 2 weeks. the new version was stable and much faster than the original.
we received bonus rewards from Axpo beyond the agreed renumeration for this extra ordinary effort.
'''),
    const SuccessData(
        title: 'Prophet: A system to run server models in various languages',
        timestamp: 1420070400,
        tags: ['protobuf', 'C#', 'python', 'julia', 'VBA', '.NET', 'smart contracts'],
        description: '''
this framework allowed quants to write (financial) models in various languages.
no matter the language chosen, the users could run the models in the Excel frontend.
• languages supported: C#, Python, julia, VBA.
• RabbitMQ for messaging
• Google protobuf for encoding
• in partnership with Axpo AG, in a team of 3 coders
'''),
    const SuccessData(
        title: 'fully automated financial trades execution system', timestamp: 1420070400, tags: ['FIX', 'IB', 'WebOE', 'Java', 'julia', 'ZeroMQ', 'finance'], description: '''
an API to execute trades with brokers. highly performant due to the technologies chosen
• supported platforms: FIX, IB, WebOE
• written in julia and Java
• communication with ZeroMQ
            '''),
// Each of which is based on economic and financial maths theory. All strategies are out-of-sample tested over decades of data.
    const SuccessData(
        title: 'fully automated trading system',
        timestamp: 1420070400,
        tags: ['portfolio optimisation', 'julia', 'trading', 'optimisation', 'ML', 'AI', 'award', 'finance'],
        description: '''
a suite of systems that allocate funds towards to financial markets.
Includes:
• a system to combine a portfolio of strategies
• a portfolio management system to 'optimally' allocate funds amongst and within the strategies
• a trade execution ssytem to send trades to various brokers and book keep the positions
• automated data input, cleaning, transformation
• a robust, N dimensional optimisation algorithm to find optimums in noisy data
• a machine learning suite used in some of the strategies

result: the system has been running successfully since 2011. tt has achieved good results for its clients and has won several awards.
it still runs fully automated, without intervention or change.
'''),
    const SuccessData(title: 'private video chat web app using WebSockets', timestamp: 1435708800, tags: ['WebSocket', 'app', 'javascript'], description: '''
• implemented a simple web app right after WebSockets were created
• my opinion was that peer-to-peer web app data communications will revolutionise the world

result: It worked and was used by family members only. Never marketed
'''),
    const SuccessData(title: 'GPU computing implementations', timestamp: 1370044800, tags: ['GPU', 'Java', 'CUDA', 'Linear Algebra'], description: '''
• implemented a few algorithms using CUDA
• formulation of existing models in linear algebraic terms
• achieved the expected, super fast speeds
'''),
    const SuccessData(
        title: 'implementation of a quantitative trading system', timestamp: 1333238400, tags: ['Matlab', 'trading', 'portfolio optimisation', 'finance'], description: '''
• implemenation of several trading models in Matlab
• a portfolio and trades management system in Matlab
            '''),
    const SuccessData(
        title: 'fully automated financial trades execution system', timestamp: 1330560000, tags: ['.Net', 'C#', 'trading', 'GUI', 'CQG', 'IB', 'finance'], description: '''
• implemenation of a trades execution system in C#
• a C# GUI to admin the system
• connected to CQG and IB
            '''),
    const SuccessData(
        title: 'Novel model for portfolio optimization with significant performance improvement',
        timestamp: 1338508800,
        tags: ['research', 'math', 'portfolio optimisation', 'finance'],
        description: '''
first i implemented around 10 different models for portfolio optimisation found in white papers and compared their 'quality'.
the quality was based on backtested performance of a portfolio of alpha generating strategies.
i then formulated a novel model for portfolio optimisation. this model was simpler than any that I had found and the 'quality' was significantly higher as well.
this model has been the basis of multiple successful trading strategies since.
this model is not published, though I would like to publish it. mot sure about legality, as I formulated this whilst working for a Swiss hedge fund, but outside of work, in my free time. also, the result might be known by now.
'''),
    const SuccessData(title: 'Heston stochastic vol model implemetation', timestamp: 1293840000, tags: ['UBS', 'C++', 'Heston', 'math', 'finance'], description: '''
• implementated and wrote a white paper on a Heston stochastic volatility model to evaluate complex financial products
• implementated in C++
• work done for UBS
'''),
    const SuccessData(title: 'Centralised Smart contracts', timestamp: 1275350400, tags: ['UBS', 'smart contract', 'math', 'Monte Carlo', 'Lua', 'finance'], description: '''
having the ability to evaluate arbitraty contracts, based on Monte Carlo simulations was considered a valuable goal at UBS.
my manager had estimated that this project would require 6 months. since there were always more urgent projects at hand, this project was never green lighted.
over a weekend, i realised that instead of creating our own smart contract language, we could simply use Lua.
the contract written in Lua could be runtime compiled into C and then embedded into our existing C++ Monte Carlo engine.
insisting on my idea, i implemented this solution in less than 3 days.
for this valuable contribution, i received monetary renumeration. however, i actually rather wanted renumeration in time.
since I had saved UBS 6 months, i wanted 1 month off to spend with my newborn kids. UBS' refusal led me to accelerate my independence from employers.
'''),
    const SuccessData(title: 'flights meta search', timestamp: 1243836600, tags: ['app', 'perl', 'travel', 'e-bookers', 'MySQL'], description: '''
• implemented a flexible flights search
• users needed to choose 4 parameters: earliest departure, latest return, shortest and longest duration
• based on these parameters, the app made multiple searches on ebookers (which allowed +- 3 day searches)
• the result was a triangular matrix showing the best prices
• i used this tool personally for years to find cheap flights for my family
• the app was never commersialised based on a flawed understanding of e-business: i thought ebookers (or any other site), does not actually like my traffic and could ban me any second
'''),
    const SuccessData(title: 'system to beat a Casino', timestamp: 1159660800, tags: ['math', 'physics', 'Nokia', 'C++', 'game'], description: '''
• having found a brand new game in a casino, i realised a flaw in the game
• the following work was based on the games' rules, as written in their brochure and as witnessed when the game was introduced
• i formulated the theoretical model (physics) that should predict the outcome of the game to a significant degree
• i implemented the model into a phone. this was pre smart phones and i think i had one of the first programmable phones (Nokia, C++)
• the phone would receive input about the game via button clicks and would vibrate to alert if a positive outcome was expected, in which case the player should bet
• since the game in question is a physical game (similar to roulette), the model had 2 free parameters that would be calibrated based on actual data (based on the physical properties, such as resistance). the systems calibration continously improves
• after implementation (and travelling; it took me 1 year to return), i arrived at the casino to test the system
• the calibration and the predictions were very accurate and precise
• unfortunatle, the casino had realised their mistake during this year and amended a rule which rendered my system useless. the change was that betting was to be done before turning the wheels (no "rien ne va plus")
• all of this was legal, but obviously the casino would not like it
'''),
    const SuccessData(title: 'achieved 1.1 in Math Vordiplom', timestamp: 1054425600, tags: ['math', 'certification'], description: '''
• achieved near perfect grade in math Vordiplom (halfway degree), which is the result of 4 oral exams after the first two years of studies
• at the Humboldt University of Berlin, in pure math
• i quit university for personal reasons after this
            '''),
    const SuccessData(title: 'won a pattern recognition competition run by Prof. Ziegler', timestamp: 986083200, tags: ['math', 'ML', 'AI', 'award'], description: '''
• entered a competition run by Prof. Ziegler at the Technical University of Berlin
• the competition was to write a algorithm to predict binary human choices
• humans were asked to enter 1 xor 0 thousands of times, as randomly as possible
• Prof. Ziegler explained that he himself competed amongst professors and researchers at a math conference with the exact same goal. And his algorithm was the winner
• my algorithm ended up winning and beating Prof. Zieglers' algorithm. my result had ca. 82% accuracy
• received a signed book by Prof. Ziegler which I soon lent to a friend --- friend, where are you nowadays? the book was a collection of the most beautiful math proofs, written by Prof. Zieglier.
'''),
    const SuccessData(title: 'coded system to archive incoming fax as digital documents', timestamp: 988675200, tags: ['C++', 'windows', 'linux'], description: '''
• on arriving fax, the system saved and archived the document digitally
• written for Carano Software, Berlin
            '''),
    const SuccessData(
        title: 'coded neural network for audio vowel classification incl. GUI for admin',
        timestamp: 993945600,
        tags: ['ML', 'AI', 'math', 'GUI', 'tcl', 'tk', 'C++'],
        description: '''
• given audio recordings of each (German) vowel, the system should learn to categorise into vowels
• MLP as neural architecture
• FFT for audio signal transformation
• coded at the Technical University of Berlin
• machine learning code in C++
• GUI in tcl/tk
• result: i worked on this project alone, whereas others worked in teams. it was an intensive summer, of coding day and night, practically living at the university. at the end, after nearly losing my mind, the system worked! it was one of the most amazing things I had seen: a machine had learned to recognise human vowels from audio. that was the beginning of my love for Machine Learning.
'''),
    const SuccessData(title: 'attended and passed Analysis at uni during high school', timestamp: 904608000, tags: ['math', 'certification'], description: '''
started attending university math lectures at the age of 16, two years before graduating high school. it was where I belonged, on the green campus of the Free University of Berlin.
i did the homework, passed the courses and received the credit which i could have used later.
            '''),
    const SuccessData(title: 'ski teacher certification', timestamp: 838857600, tags: ['sport', 'certification'], description: '''
at the age of 14, i entered a ski teacher certification program (run by the Wiener Ski Verband, Austria), as a means to ski cheaply. even though the minimum age was 15, i participated, worked hard and passed the exams (barely).
this made me a qualified ski teacher. interestingly, I had just started skiing 2 years earlier. everyone else attending the program had been skiing since their childhood. it would have even seemed that skiing was not 'for me', as I did not enjoy the cold, was scared of heights and fast speeds, was thin and weak and not well balanced.
yet, i did enjoy it and skiied so much in the two years before these exams, that i made it. barely, but I made it.
            '''),
    const SuccessData(title: 'German U18 water polo champion', timestamp: 928195200, tags: ['sport', 'award'], description: '''
• German Champion of U18 in 1998.
• 4 times German Vice Champion of U16 and U18.
• selected for the German national team, but refused to join as i did not want to attend the military service, which was a connected necessity.
'''),
    const SuccessData(title: 'coded graphical labyrinth game', timestamp: 825638400, tags: ['pascal', 'game'], description: '''
since ca. 8 years old, I had been coding a lot. most of them I cannot remember.
the one game i do remember was a graphical labyrinth game which only showed the immediate surroundings of the user.
i even remember coding and formatting my computer without a screen, which my mother took away, thinking that was the computer. that is how intimate I was with my computer. i knew what it was doing based on my commands and the sounds it would make.
            '''),
    const SuccessData(title: 'jumped from German D4 to D1 within 2 years', timestamp: 841536000, tags: ['language'], description: '''
when i just arrived in Germany, i joined an international school that offered 4 levels of German: D4 (beginners), D3B, D3A, D2 (fluent) and D1 (native).
the normal progression from D4 was to advance a level per year, until either D3A or D2 in best cases. D2 was mostly inhabited by kids that grew up in Germany with foreign parents.
i went from D4 to D2 within one year. after that success, i made it my goal to make it to D1, which was considered absurd. Despite the discouragement, i managed to join D1 after another year, in grade 9.
though i was very proud of the achievement, it turned to be a mistake. i did not enjoy the class and should have just chilled in D2. eventually, i asked to be moved back to D2.
nonetheless, i count it as a sucesss.
            '''),
    const SuccessData(title: 'self derived formula to calculate curve length', timestamp: 786240000, tags: ['math'], description: '''
at age 13, i became curious as to how my math teacher could calculate angels of a triangle so precisely. he told me about trigonometry.
i spent months self studying trigonometry and then calculus from a book at the library. the most advanced calculations that I was able to do, were integrals by using infinite sums of infinitisimal rectangles under a curve.
i still remmeber lying to a teacher about the self study out of shame and instead saying that someone taught me.
soon i asked another teacher what else one could calculate in Calculus. he mentioned that curve lengths are much more difficult than areas under a curve.
it took me weeks of thinking and finally i woke up one morning with the answer: sum infinate infinitisimal triangle hypothenuses using pythagoras.
after deriving and applying the formula, i tested the result vs an applied maths app. the result matched and this achievement became my proudest.
            '''),
    const SuccessData(title: 'skipped grades 3 and 4', timestamp: 683683200, tags: ['certification'], description: '''
unfortunatle, due to personal reasons, i never enjoyed school. when changing to a 'better' school, my father suggested i take the exam for the next level up.
i did and passed, after which my father suggested that i should take another exam for another level higher. i did and passed again, resulting in me skipping grades 3 and 4.
i always count it as a success, just because i did not like school. though now, i am not sure whether it was a good idea and am not sure whether to advise the same for others in a similar situation.
            '''),
    const SuccessData(title: 'won neighbourhood chess championship', timestamp: 688953600, tags: ['award', 'game'], description: '''
at a tender age and after having played chess just a few times, i managed to win 3 games at the neighbourhood chess championship (open to all ages), playing only against adults and defeating the reigning champion in the final.
i always considered this a reflection on the quality of the other chess players, since I was basically a beginner. after telling the story to my family recently, they urged my to rethink it as my own success. so I do now.
my chess 'career' consisted of playing slightly seriously as a tennager, achieving an ELO of ca. 1900 and stopping after realising the need to study openings.
i did earn pocket money over many years to come.
            '''),
    const SuccessData(title: 'raised 8MM CHF for ecamos', timestamp: 1370044800, tags: ['finance', 'sales'], description: '''
ecamos is a hedge fund in Switzerland. after joining them as a partner, my role was actually Head of Research, Trading and IT.
i did however end up giving most presentations and raised 8MM CHF, which was the highest ticket at that moment.
since i geniunely dislike 'selling' anything, this was an achievement outside my comfort zone, begotten via a year long correspondence with the client.
            '''),
    const SuccessData(title: 'winning games at Berlin Expo', timestamp: 852662771, tags: ['award', 'game'], description: '''
even though i am not really a gamer, i do appreciate gaming as a culture, an industry, an activity, a learning exprience ~ at the Berlin Expo, i entered 2 gaming competitions: VR pacman where i emerged 1st overall ~ PS car racing where i emerged 2nd overall
            '''),
    const SuccessData(title: 'worked at UBS QRC', timestamp: 1249084800, tags: ['math', 'UBS', 'finance'], description: '''
i had the amazing pleasure of working at the QRC Team at UBS, in Zurich, Switzerland.
the QRC (Quantitative Risk Control) team consisted of the most talented indivuals that I had ever seen.
not only were the team members mostly PhDs in Math or Theoretical Physics, they were Olympiad Medalist winners or similar.
and then there was me.
getting in was an extremely difficult experience. after being told 'no' by HR, I insisted and got an interview.
conducting the first interviews on the phone, I had to solve math problems in my head because I thought it would just be a friendly call. i was wrong.
afterwards, I spent an entire day being asked tough math questions by around 10 people. at the end, HR again rejected me, but the team wanted me.
against all odds, i got the job. i would go on to get a 'record time' promotion, aparently 'unheard of', after less than 6 months at UBS, during the height of the 2009 financial crisis.
            '''),
    const SuccessData(title: 'EUREX Exchange Trader examination', timestamp: 1267401600, tags: ['finance', 'certification'], description: '''
passed the exam.
            '''),
    const SuccessData(title: 'Financial Risk Management Certification (GARP)', timestamp: 1262649600, tags: ['finance', 'certification'], description: '''
to get a better standing in the financial community, i applied, studied for and passed the FRM exam at GARP.
            '''),
    const SuccessData(title: 'trading system awards', timestamp: 1585699200, tags: ['award', 'finance'], description: '''
the trading system that i created has won several awards over the years, including:
• Barclay Managed Funds Report #6 Past Five Years category for 2020-Q4
• BarclayHedge #3 for Diversified Traders Managing More Than 10MM for 2020.
• BarclayHedge #1 for Diversified Traders Managing More Than 10MM for 2020-11.
• BarclayHedge #4 for Diversified Traders Managing More Than 10MM for 2020-01.
• BarclayHedge #8 for CTAs Managing More Than 10M for 2019-11.
• Barclay Managed Funds Report #16 Past Three Years category for 2019-Q2.
• BarclayHedge #7 for Systematic Traders for 2018-12.
• BarclayHedge #7 for CTAs Managing More Than 10MM for 2018-01.
• Barclay Managed Funds Report #10 Past Year category for 2017-Q4.
• Hedge Funds Review (Europe): Best Managed Futures CTA Emerging Manager 2017.
• CTA Intelligence: European Performance Awards 2017 Winner.
• HFM European Performance Awards 2017: Best Newcomer.
• Best CTA Multi Strategy Fund Manager - Europe - alternativeinvestmentawards
'''),
    const SuccessData(title: 'winner of Swiss ‘Quiz on Korea 2013’', timestamp: 1370044800, tags: ['award'], description: '''
i joined a competition called 'Quiz on Korea'. I managed to (barely) win the Swiss national competition.
this made me the Swiss representative at the international 'Quiz on Korea' world championships in Seoul. i did not do well at the finals for weird reasons, but still consider it a success to have made it that far.
            '''),
    const SuccessData(title: 'intercontinental move to Canada', timestamp: 1627862400, tags: ['travel'], description: '''
moving to North America is always a challenge. for our kids education, we decided to take on this adventure.
we arrived in Canada on the same day that our encode competition started. it was quite tough managing the competition whilst settling into a completely new place.
after getting the visa, arriving, getting a car, a house, i consider this a success.
            '''),
    const SuccessData(title: 'born', timestamp: 373723200, description: '''
can being born count as an success or achievement? considering that birth is a difficult and dangerous process, yes, it can.\n
many people celebrate birth anniversaries, so even pride in being born is considered normal.\n
relevantly, this entry provides an anchor in time to contextualize the other successes.
            '''),
    const SuccessData(title: 'wrote independent proof for uncountability and sparsity of the Cantor set', timestamp: 1038771048, tags: ['math', 'research'], description: '''
          in my 2nd year at Humboldt Universität zu Berlin, Prof. Naumann showed us an advanced proof for the uncountability and 0 Lebueque measure of the Cantor set.
          he remarked that he did not know of any elementary proof for this statement and that this was surprising. i took the challenge and produced an elementary proof after 2 months of thinking.
          Prof. Naumann was impressed and decided to co-publish and name the central function used after my name. before publishing, for due diligence, Prof. Naumann checked whether this proof was really novel.
          it was not; the exact same proof had been published in the 1970s and he had just not heard about it before.
          that made my proof not novel but still counts as independent research.
            '''),
    const SuccessData(title: 'survivor of 5 kidnappings', timestamp: 468378000, tags: ['trauma', 'mental health', 'survival'], description: '''
          in my childhood, i have been a victim of 5 kidnapping attempts, 3 of which were successful. i also lived for ca. 6 years as a prisoner.
          in my opinion, i have dealt with it relatively well, despite suffering from almost-life-long depression as a result.
          the kidnappings very familial, but unfortunately no less dramatic or traumatising. events included strangers, criminality, continents, conspiracy and drama.
          my life as a prisoner, as it turns out, was entirely in my head though. the experience was geniune and full of fear, but in actuality, i just 'never' talked and it was assumed that my environment was voluntary.
          i thought of running to freedom or telling someone everyday for a few years and less in the last years.
          none the less, though too quietly, I have still lived a good enough life after finding freedom.
          one of the worst consequences has been the fact that up until ca. my 40th birth anniversary, i have been ashamed of my ability of coding ~ i have been coding since a very young age and always felt like i could code "anything" using any language ~ but, i was always ashamed of this skill and hid it as much as possible ~ finally, i asked my wife 'is it weird to be ashamed of being good with computers?' ~ crazy!
            '''),
    const SuccessData(title: 'hypnosis for raising self esteem', timestamp: 1483814771, tags: ['trauma', 'mental health', 'survival'], description: '''
as a result of my childhood traumas, my self esteem was very low for a long time ~ even though i had received many awards, promotions, compliments, i always considered myself an impostor ~ yes, i had severe impostor syndrome ~
i was even ashamed of being good with computers so much so that i actively avoided such roles and yet ended up creating computer systems for any team i joined ~
after receiving lots of positive feedback, i recognised impostor syndrome ~ i went to a hypnosist to make my mind 'super humanly confident, just shy of irrational' ~ 
it worked extremely well and i have lost all humility since ~ i now openly and actively tell about my strengths ~ and also weaknesses ~ i always do my best to be precise and not exagerate
            '''),
  ];

  List<SuccessData> searchCVList = [];

  initList() {
    mainCvList = imiSuccesses;
    mainCvList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  initKeywordList() {
    mainCvList.forEach((element) {
      element.tags?.forEach((tagElement) {
        if (!keywordList.contains(tagElement.toLowerCase())) {
          keywords.add(tagElement.toLowerCase());
        }
      });
    });
    keywords = keywords.toSet().toList();
    keywords.sort();
  }

  addInKeywordList(value) {
    keywordList.add(value.toString().toLowerCase());
    refreshList();
    notifyListeners();
  }

  openCloseSuggestionView() {
    isOpenSuggestionView = !isOpenSuggestionView;
    notifyListeners();
  }

  removeInKeywordList(value) {
    keywordList.removeWhere((element) => element == value);
    refreshList();
    notifyListeners();
  }

  refreshList() {
    searchCVList = mainCvList.where((element) => (element.tags ?? []).any((searchKeyword) => keywordList.contains(searchKeyword.toLowerCase()))).toList();
    print(searchCVList);
  }
}
