### Twitter API ###

#### Setting up the environment ####
setwd("path")

require(httr)
require(jsonlite)
require(dplyr)
require(rtweet)
require(tidytext)
require(stringr)
library(mongolite)
library(ggplot2)
library(syuzhet)
library(rpart)

#### Forbind til Twitter API ####

## Connect API keys ##
bearertoken <- Sys.getenv("AAAAAAAAAAAAAAAAAAAAAGN0jAEAAAAASvEvdMB4VyRmThek0xYvsj3XpU4%3D6NP2TRf3k9eiY351TSjk73YHijiacCNRipyI9bMZ3Oj1YhmmjM")
headers <- c(`Authorization` = sprintf('Bearer %s', bearertoken))

access_token <- '1590297873060708359-870HzrqJG61sU38TZaeX5Zx9EDMFor'
access_secret <- 'secret'

bearer_token<-'AAAAAAAAAAAAAAAAAAAAAGN0jAEAAAAASvEvdMB4VyRmThek0xYvsj3XpU4%3D6NP2TRf3k9eiY351TSjk73YHijiacCNRipyI9bMZ3Oj1YhmmjM'

## Først skal man connecte til Twitter API med auth_setup_default()
auth_get()

#### Test af indhentning af tweets #### 

## Hent alle tweets med et bestemt ord eller #hashtag ## 
# n bestemmer antallet af tweets. n kan være =Inf
# "include_rts = FALSE" for at undgå retweets

hashtag_test<-search_tweets("#bitcoin",include_rts = FALSE, n =50)

keyword_test_eng <- search_tweets("crypto", lang = "en", include_rts = FALSE, n=50)
keyword_test_no <- search_tweets("crypto", lang = "no", include_rts = FALSE, n=50)

#Tager kun dato og tekst 
keyword_test_eng1 <- keyword_test_eng[c(1, 4)]

## load tweets by accout handle 
example_user<-search_tweets("example_user", n=50)

## getting information on specific account 
example_profile<-search_users("profilename")

#### Indhentning af tweets ####

## Crypto -keyword ##
keyword_crypto <- search_tweets("crypto", lang = "en", include_rts = FALSE, n=100000)

keyword_crypto_no<-search_tweets("krypto", lang = "no", include_rts = FALSE, n=100000)


#Tager kun dato og tekst 
keyword_crypto <- keyword_crypto[c(1, 4)]
keyword_crypto_no<-keyword_crypto_no[c(1,4)]

## Bitcoin - keyword ##
keyword_bitcoin<-search_tweets("bitcoin", lang = "en", include_rts = FALSE, n=10000)

#Tager kun dato og tekst 
keyword_bitcoin <- keyword_bitcoin[c(1, 4)]

## Ethereum - keyword ##
keyword_ether<-search_tweets("ethereum", lang = "en", include_rts = FALSE, n=10000)

#Tager kun dato og tekst 
keyword_ether <- keyword_ether[c(1, 4)]

#### MongoDB ####

## Opret forbindelse til databasen ## 
mongo_crypto<-mongo(collection = "crypto", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

mongo_crypto_no<-mongo(collection = "crypto_no", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

mongo_btc<-mongo(collection = "bitcoin", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

mongo_eth<-mongo(collection = "ethereum", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

## Hent data ind i Mongo ## 

#Konverter dataframes til json
#Ændr navnet i filen til datoen tweets er hentet ned 

keyword_crypto_json <- jsonlite::toJSON(keyword_crypto,collapse='',byrow=TRUE)
crypto_file<-writeLines(keyword_crypto_json,sep='\n','kw_crypto_2301.txt')

keyword_crypto_no_json <- jsonlite::toJSON(keyword_crypto_no,collapse='',byrow=TRUE)
writeLines(keyword_crypto_no_json,sep='\n','kw_crypto_no_2301.txt')

keyword_bitcoin_json<-jsonlite::toJSON(keyword_bitcoin,collapse='',byrow=TRUE)
writeLines(keyword_bitcoin_json,sep='\n','kw_bitcoin_2301.txt')

keyword_eth_json<-jsonlite::toJSON(keyword_ether,collapse='',byrow=TRUE)
writeLines(keyword_eth_json,sep='\n','kw_eth_2301.txt')

#Importer filen til mongo 
mongo_crypto$import(file('kw_crypto_2301.txt','r'))
mongo_crypto_no$import(file('kw_crypto_no_2301.txt', 'r'))

mongo_btc$import(file('kw_bitcoin_2301.txt', 'r'))

mongo_eth$import(file('kw_eth_2301.txt', 'r'))

#Tjek hvor meget der i gemt i collection 
mongo_crypto$count()
mongo_crypto_no$count()
mongo_btc$count()
mongo_eth$count()

## Henter dataen ind ##
crypto_tweets<-mongo_crypto$find('{}')
crypto_no_tweets<-mongo_crypto_no$find('{}')
bitcoin_tweets<-mongo_btc$find('{}')
ethereum_tweets<-mongo_eth$find('{}')

crypto_tweets <- crypto_tweets[c(1, 2)]

## Fjerner duplicated tweets ##
crypto_tweets<-crypto_tweets[!duplicated(crypto_tweets$full_text),]
crypto_no_tweets<-crypto_no_tweets[!duplicated(crypto_no_tweets$full_text),]
bitcoin_tweets<-bitcoin_tweets[!duplicated(bitcoin_tweets$full_text),]
ethereum_tweets<-ethereum_tweets[!duplicated(ethereum_tweets$full_text),]

#### Sentiment Analyse #### 

### Syuzhet ### 

## Test af sentiment score ##

#Henter 100 tweets ind 
test_df<-mongo_crypto$find('{}', limit=10000)

# Extract date from datetime column and overwrite datetime column
test_df <- test_df %>%
  mutate(created_at = str_extract(created_at, "([0-9]{4}-[0-9]{2}-[0-9]{2})"))

#Opretter kolonne med NA values 
test_df$sentiment<-NA

#Laver sentiment score 
test_df$sentiment<-get_sentiment(test_df$full_text,  method = "syuzhet",)

#Ændrer til ikke at være scientific 
test_df$sentiment<-format(test_df$sentiment, scientific = FALSE)

#Samler per dag og laver gennemsnit 

mean_test<- test_df %>%
  group_by(created_at) %>%
  mutate(average = mean(sentiment))

dato_test<- mean_test %>%
  distinct(created_at, .keep_all = TRUE)

### Udregning af sentiment score ### 

## Ændrer dato kolonnen til kun dato ##
# Extract date from datetime column and overwrite datetime column
crypto_tweets <- crypto_tweets %>%
  mutate(created_at = str_extract(created_at, "([0-9]{4}-[0-9]{2}-[0-9]{2})"))

crypto_no_tweets <- crypto_no_tweets %>%
  mutate(created_at = str_extract(created_at, "([0-9]{4}-[0-9]{2}-[0-9]{2})"))

bitcoin_tweets <- bitcoin_tweets %>%
  mutate(created_at = str_extract(created_at, "([0-9]{4}-[0-9]{2}-[0-9]{2})"))

ethereum_tweets <- ethereum_tweets %>%
  mutate(created_at = str_extract(created_at, "([0-9]{4}-[0-9]{2}-[0-9]{2})"))

#Tilføjer kolonne til sentiment score med NA values 
crypto_tweets$sentiment<-NA
crypto_no_tweets$sentiment<-NA
bitcoin_tweets$sentiment<-NA
ethereum_tweets$sentiment<-NA

#Laver sentiment score 
crypto_tweets$sentiment<-get_sentiment(crypto_tweets$full_text, method = "syuzhet",)

crypto_no_tweets$sentiment<-get_sentiment(crypto_no_tweets$full_text, method = "syuzhet", language="NO")

bitcoin_tweets$sentiment<-get_sentiment(bitcoin_tweets$full_text,  method = "syuzhet",)

ethereum_tweets$sentiment<-get_sentiment(ethereum_tweets$full_text,  method = "syuzhet",)

#Samler per dag og laver gennemsnit 

mean_crypto_tweets<- crypto_tweets %>%
  group_by(created_at) %>%
  mutate(average = mean(sentiment))

mean_crypto_tweets<- mean_crypto_tweets %>%
  distinct(created_at, .keep_all = TRUE)

mean_crypto_no_tweets<- crypto_no_tweets %>%
  group_by(created_at) %>%
  mutate(average = mean(sentiment))

mean_crypto_no_tweets<- mean_crypto_no_tweets %>%
  distinct(created_at, .keep_all = TRUE)

mean_bitcoin_tweets<- bitcoin_tweets %>%
  group_by(created_at) %>%
  mutate(average = mean(sentiment))

mean_bitcoin_tweets<- mean_bitcoin_tweets %>%
  distinct(created_at, .keep_all = TRUE)

mean_ethereum_tweets<- ethereum_tweets %>%
  group_by(created_at) %>%
  mutate(average = mean(sentiment))

mean_ethereum_tweets<- mean_ethereum_tweets %>%
  distinct(created_at, .keep_all = TRUE)

#Fjerner ikke relevante kolonner 
mean_crypto_tweets<-mean_crypto_tweets[c(1, 4)]
mean_crypto_no_tweets<-mean_crypto_no_tweets[c(1, 4)]
mean_bitcoin_tweets<-mean_bitcoin_tweets[c(1, 4)]
mean_ethereum_tweets<-mean_ethereum_tweets[c(1, 4)]


## Læg dataen i mongo ##
mongo_mean_crypto<-mongo(collection = "mean_crypto", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)
mongo_mean_no_crypto<-mongo(collection = "mean_no_crypto", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)
mongo_mean_bitcoin<-mongo(collection = "mean_bitcoin", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)
mongo_mean_ethereum<-mongo(collection="mean_ethereum", db= "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

#Konverter dataframes til json

mean_crypto_json <- jsonlite::toJSON(mean_crypto_tweets,collapse='',byrow=TRUE)
mean_crypto_file<-writeLines(mean_crypto_json,sep='\n','mean_crypto.txt')

mean_crypto_no_json <- jsonlite::toJSON(mean_crypto_no_tweets,collapse='',byrow=TRUE)
mean_crypto_no_file<-writeLines(mean_crypto_no_json,sep='\n','mean_crypto_no.txt')

mean_bitcoin_json <- jsonlite::toJSON(mean_bitcoin_tweets,collapse='',byrow=TRUE)
mean_bitcoin_file<-writeLines(mean_bitcoin_json,sep='\n','mean_bitcoin.txt')

mean_ethereum_json <- jsonlite::toJSON(mean_ethereum_tweets,collapse='',byrow=TRUE)
mean_ethereum_file<-writeLines(mean_ethereum_json,sep='\n','mean_ethereum.txt')

#Importer filen til mongo 
mongo_mean_crypto$import(file('mean_crypto.txt','r'))
mongo_mean_no_crypto$import(file('mean_crypto_no.txt','r'))
mongo_mean_bitcoin$import(file('mean_bitcoin.txt','r'))
mongo_mean_ethereum$import(file('mean_ethereum.txt','r'))

#### Handelsvolumen #### 

#Henter datasættet 
query_result <- read.csv("path")

# Fjerner alle rækker med Fiat 
query_result <- query_result %>%
  filter(!Is.Fiat=="true")

## Samler alle handelsvolumer 
total_handel <- query_result %>%
  group_by(Date) %>%
  summarise(sum = sum(Cost.Nok))

## Samler kun Bitcoin 
bitcoin_handel <- subset(query_result, Currency.ID == "BTC")

#### Lineær regression ####

## Indhenter datasæt ##

#Opret forbindelse til mongo
mongo_mean_crypto<-mongo(collection = "mean_crypto", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)
mongo_mean_no_crypto<-mongo(collection = "mean_no_crypto", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)
mongo_mean_bitcoin<-mongo(collection = "mean_bitcoin", db = "bachelor_project", url = "mongodb://localhost", verbose = TRUE)

#Indhenter data
crypto_sentiment<-mongo_mean_crypto$find('{}')
crypto_no_sentiment<-mongo_mean_no_crypto$find('{}')
bitcoin_sentiment<-mongo_mean_bitcoin$find('{}')

#Ændrer kolonnenavne 
colnames(crypto_sentiment)[colnames(crypto_sentiment) == "created_at"] <- "Date"
colnames(crypto_sentiment)[colnames(crypto_sentiment) == "average"] <- "Crypto Sentiment"
colnames(crypto_no_sentiment)[colnames(crypto_no_sentiment) == "created_at"] <- "Date"
colnames(crypto_no_sentiment)[colnames(crypto_no_sentiment) == "average"] <- "Crypto NO Sentiment"
colnames(bitcoin_sentiment)[colnames(bitcoin_sentiment) == "created_at"] <- "Date"
colnames(bitcoin_sentiment)[colnames(bitcoin_sentiment) == "average"] <- "Bitcoin Sentiment"


##Sætter datasættene sammen 
df_total_handel<- merge(total_handel,  crypto_sentiment, by = "Date")
df_total_handel<- merge(df_total_handel,  crypto_no_sentiment, by = "Date")
df_total_handel<- merge(df_total_handel, bitcoin_sentiment, by = "Date")

#Ændrer kolonnenavn 
colnames(df_total_handel)[colnames(df_total_handel) == "sum"] <- "Handelsvolumen"

## Lineær Regression ##

lm_simple<-lm(y ~x1 + x2 +x3, data=df_total_handel)
summary(lm_simple) 
summary(lm_simple)$r.squared 

## LM med træning/test ##
lm_train <- lm_simple(y ~ x1 + x2 +x3, data = train)

# Make predictions on the test set
predictions <- predict(lm_test, newdata = test)

# Evaluate the model's performance
sum_squared_residuals <- sum((test$Handelsvolumen - predictions)^2)
mean_response <- mean(test$Handelsvolumen)
sum_squared_total <- sum((test$Handelsvolumen - mean_response)^2)

R_squared <- 1 - (sum_squared_residuals / sum_squared_total)

## Gemmer dataframen ##
write.csv(df_total_handel, file = "df_total_handel.csv")

## LM Bitcoin ##

#Laver ny datasæt 
df_btc_handel<- merge(bitcoin_handel,  crypto_sentiment, by = "Date")
df_btc_handel<- merge(df_btc_handel,  crypto_no_sentiment, by = "Date")
df_btc_handel<- merge(df_btc_handel, bitcoin_sentiment, by = "Date")

df_btc_handel<-df_btc_handel[c(1, 4, 8, 9, 10)]

colnames(df_btc_handel)[colnames(df_btc_handel) == "Cost.Nok"] <- "Handelsvolumen"

#Definerer variabler 
y_BTC<-df_btc_handel$Handelsvolumen
x1_btc<-df_btc_handel$`Crypto Sentiment`
x2_btc<-df_btc_handel$`Crypto NO Sentiment`
x3_btc<-df_btc_handel$`Bitcoin Sentiment`

#Lineær regression
lm_btc<-lm(y_BTC ~ x1_btc + x2_btc +x3_btc , data=df_btc_handel)

summary(lm_btc)

#### Decision Tree ####

## Regression tree ##

#Alle handler 
regtree <- rpart(formula = y ~ x1 + x2 + x3, data = df_total_handel)

regtree$node.label <- format(regtree$node.label, scientific = FALSE)

plot(regtree)
text(regtree)

predictions <- predict(regtree, newdata = df_total_handel)

#Kun BTC
regtree_btc <- rpart(formula = y_BTC ~ x1_btc + x2_btc + x3_btc, data = df_btc_handel)
plot(regtree_btc)
text(regtree_btc)

predictions_btc <- predict(regtree_btc, newdata = df_btc_handel)


#### Plot ####

### Crypto Sentiment Score ###

# Remove the row with the date "2023-01-01"
crypto_sentiment <- subset(crypto_sentiment, Date != "2023-01-01")

# Fjerner årstallet med regex
crypto_sentiment$Date <- gsub("^\\d{4}-", "", crypto_sentiment$Date)

#Plot
ggplot(data=crypto_sentiment, 
       aes(x = Date, y = `Crypto Sentiment`, group=1))+
  geom_line(color="black")+
  ggtitle("Gennemsnitlige sentiment score på crypto Tweets")+
  labs(x="Dato",y="Sentiment Score")

### Crypto NO Score ###

# Remove the row with the date "2023-01-01"
crypto_no_sentiment <- subset(crypto_no_sentiment, Date != "2023-01-01")

# Fjerner årstallet med Regex
crypto_no_sentiment$Date <- gsub("^\\d{4}-", "", crypto_no_sentiment$Date)

#Plot
ggplot(data=crypto_no_sentiment, 
       aes(x = Date, y = `Crypto NO Sentiment`, group=1))+
  geom_line(color="black")+
  ggtitle("Gennemsnitlige sentiment score på norske krypto Tweets")+
  labs(x="Dato",y="Sentiment Score")


### Bitcoin score###

# Remove the row with the date "2023-01-01"
bitcoin_sentiment <- subset(bitcoin_sentiment, Date != "2023-01-01")

# Fjerner årstallet med regex
bitcoin_sentiment$Date <- gsub("^\\d{4}-", "", bitcoin_sentiment$Date)

#Plot
ggplot(data=bitcoin_sentiment, 
       aes(x = Date, y = `Bitcoin Sentiment`, group=1))+
  geom_line(color="black")+
  ggtitle("Gennemsnitlige sentiment score på Bitcoin Tweets")+
  labs(x="Dato",y="Sentiment Score")

### Alle sentiment ###
samlet_sentiment<- merge(crypto_sentiment, crypto_no_sentiment, by = "Date")
samlet_sentiment<- merge(samlet_sentiment, bitcoin_sentiment, by = "Date")

ggplot(samlet_sentiment, aes(Date)) +  
  geom_line(aes(y = `Crypto Sentiment`,group=1 ), color = "blue") +
  geom_line(aes(y = `Crypto NO Sentiment`, group=2 ), color = "red") +
  geom_line(aes(y = `Bitcoin Sentiment`, group=3 ), color = "green") +
  scale_colour_manual("Sentiment", 
                      breaks = c("Crypto", "Krypto NO", "Bitcoin"),
                      values = c("Crypto"="blue","Krypto NO"= "red", "Bitcoin" ="green"),
                      guide = 'legend') +
  ggtitle("Gennemsnitlige sentiment score")+
  labs(x="Dato",y="Sentiment Score")
                     