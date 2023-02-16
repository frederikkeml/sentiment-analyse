# Bachelorprojekt i dataanalyse omkring sentiment analyse og kryptovalutahandel

This final bachelor’s project in data analysis investigates the relationship between what is written on the social media platform Twitter about cryptocurrency, and the trade history of cryptocurrencies in Norway on the Norwegian crypto exchange Firi, specifically in November and December 2022. 
Twitter’s API was used to collect tweets daily from mid-November to the end of December 2022, focusing on the keywords “crypto”, “krypto” (in Norwegian) and “Bitcoin”. Bitcoin was the first cryptocurrency, and still holds the largest market cap. Furthermore, Bitcoin is, on average, the most traded coin on Firi’s exchange.  For these reasons, Bitcoin was selected as a separate keyword. 
This resulted in approximately 270.000, 600, and 174.000 tweets about crypto, krypto, and Bitcoin respectively. All tweets, together with the timestamp of when they were written were stored in a local database. 

Natural language processing was then used to subtract the sentiment, which is whether the text is negative or positive, from each tweet. Each tweet  was then allocated a score between -10 and +10. After assigning each tweet a sentiment score, the mean score for each day was calculated for each keyword. 
  This analysis showed that during the biggest events in the crypto industry, which was FTX CEO Sam Bankman-Fried’s arrest and subsequent release on bail, the sentiment score shifted in both directions. First negatively during the arrest, but later positively during his release. Additionally, over the Christmas holiday, the score shifted in a positive direction again.

A multiple linear regression was then used to find correlations between the trade volume in Norway in the same period, and the sentiment scores of the three keywords. This model showed that the sentiment of crypto is significant to the volume of trade on Firi’s platform. The model also showed a R^2 score of 0,3773, meaning that around 38% of the trade volume can be explained by the independent variables (sentiment of the keywords). 
The same model was then used to find correlations between the trade of only Bitcoin, with the same independent variables. This showed similar results, but with weaker significance than the previous iteration. 

Another machine learning model, regression trees, was then used to predict the trade volume with the same independent variables as above. This model was chosen because the results are more easily interpreted than those of the linear regression, especially for employees of a company or their stakeholders who have little or no knowledge of statistics or machine learning. 

The analysis shows that trade volume in Norway on Firi’s platform decreases when there is a positive sentiment score on tweets about cryptocurrency in November and December 2022. 

It is then discussed how to expand the analysis to include longer time periods or other cryptocurrencies for better yielding results. Additionally, the future of both cryptocurrency,  Twitter as a social media platform to discuss and share news about cryptocurrency, and blockchain is reviewed. 

