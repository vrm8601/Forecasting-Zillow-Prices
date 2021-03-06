####### Data Cleaning #########
# Import packages
library(forecast)
library(dplyr)
library(fpp2)
library(seasonal)
library(urca)
library(tseries)
# Read in data
data <- read.csv("C:\\Users\\vrm8601\\Documents\\DSC 551\\Final\\Metro_median_sale_price_uc_SFRCondo_raw_month.csv")
# Get just Philadelphia
phl <- data %>% filter(RegionName=="Philadelphia, PA")
# Remove missing and unnecessary information to get time series
phl1 <- phl[,-c(1:5)]
# Transpose to get time series format
phl.t <- t(phl1)
# Make index a column so that I can change the format of the date
df <- cbind(date = rownames(phl.t), phl.t)
rownames(phl.t) <- 1:nrow(phl.t)
# Remove the X in from of each date and replace "." with "-"
df=data.frame(df)
df$date <- gsub("^.{0,1}", "", df$date)
df$date <- gsub("\\.","-",df$date)
# Set as datetime object and as row names again
df$date <- as.Date(df$date,"%Y-%m-%d")
rownames(df) <- df$date
df <- df[ ,"V2", drop=FALSE]
# Make V2 column (which is the ZHVI) as numeric
df$V2 <- as.numeric(df$V2)
# Create time series
ts <- ts(df[,1], frequency = 12, start=c(2008,2), end=c(2020,7))


############ Introductory Plots ################
# Plot time series
autoplot(ts)+
  ggtitle("Monthly Raw Median Sale Price for Homes in Philadelphia, PA")+
  xlab("Year")+
  ylab("Median Sale Price ($)")
# Seasonal plot
ggseasonplot(ts)+
  ggtitle("Seasonal Plot for Time Series")+
  ylab("Median Sale Price ($)")
# seasonal subseries plot
ggsubseriesplot(ts)+
  ggtitle("Seasonal Subseries Plot")+
  xlab("Month")+
  ylab("Median Sale Price ($)")
# lag plot
gglagplot(ts ,lags=24)+
  ggtitle("Lag Plot")+
  xlab("Median Sale Price ($)")+
  ylab("Median Sale Price ($)")
# ACF
ggAcf(ts, lag= 36)+
  ggtitle("ACF Plot")


############# Four Benchmark Methods ################
# Train test split
ts.train <- head(ts,120)
ts.test <- tail(ts,30)
# Naive method
fit.na <- naive(ts.train, h=30)
# Seasonal naive method
fit.sn <- snaive(ts.train, h=30)
# Average method
fit.me <- meanf(ts.train, h=30)
# Drift method
fit.dr <- rwf(ts.train, h=30, drift=TRUE)
# Plot 
autoplot(ts, series="Original")+
  autolayer(fit.na, PI=FALSE, series="Naive")+
  autolayer(fit.sn, PI=FALSE, series="Seasonal Naive")+
  autolayer(fit.me, PI=FALSE, series="Average")+
  autolayer(fit.dr, PI=FALSE, series="Drift")+
  ggtitle("Four Benchmark Methods for Forecasting \n
Median Sale Price for Homes in Philadelphia, PA")+
  xlab("Date")+
  ylab("Median Sale Price ($)")
# Accuracy 
a.na <-accuracy(fit.na, ts.test)
a.sn <-accuracy(fit.sn, ts.test)
a.me <-accuracy(fit.me, ts.test)
a.dr <-accuracy(fit.dr, ts.test)
RMSE=c(a.na["Test set","RMSE"],a.sn["Test set","RMSE"],a.me["Test set","RMSE"],a.dr["Test set","RMSE"])
MAE = c(a.na["Test set","MAE"], a.sn["Test set","MAE"],a.me["Test set","MAE"],a.dr["Test set","MAE"])
results <-data.frame(RMSE, MAE, row.names = c("Naive","Seasonal Naive", "Average","Drift"))
results[order(results$RMSE),]
# Check residuals
checkresiduals(fit.sn)


################ Decomposition ###############
## STL 
stl <- stl(ts,s.window="periodic",t.window=13)
stl %>%
  autoplot()+
  ggtitle("STL Decomposition of Median Sale Price of
          Homes in Philadelphia, PA")+
  xlab("Year")

## Seasonally adjusted
sa <- seasadj(decompose(ts))
autoplot(sa, series="Seasonally Adjusted")+
  autolayer(ts, series="Original")+
  ggtitle("Seasonally Adjusted Time Series of Median Sale Price of \n Homes in Philadelphia, PA")+
  xlab("Year")+
  ylab("Seasonally Adjusted Median Home Sale Price ($)")


### Benchmark Methods with Seasonally Adjusted(SA) Data ###
# Train test split
sa.train <- head(sa,120)
sa.test <- tail(sa,30)
# Naive method
fit.na.sa <- naive(sa.train, h=30)
# Average method
fit.me.sa <- meanf(sa.train, h=30)
# Drift method
fit.dr.sa <- rwf(sa.train, h=30, drift=TRUE)
# Plot 
autoplot(sa, series="Original")+
  autolayer(fit.na.sa, PI=FALSE, series="Naive")+
  autolayer(fit.me.sa, PI=FALSE, series="Average")+
  autolayer(fit.dr.sa, PI=FALSE, series="Drift")+
  ggtitle("Four Benchmark Methods for Forecasting \n Median Sale Price for Homes in Philadelphia, PA on \n Seasonally Adjusted Data")+
  xlab("Date")+
  ylab("Median Sale Price ($)")
# Accuracy 
a.na.sa <-accuracy(fit.na.sa, sa.test)
a.me.sa <-accuracy(fit.me.sa, sa.test)
a.dr.sa <-accuracy(fit.dr.sa, sa.test)
RMSE1=c(a.na["Test set","RMSE"],a.sn["Test set","RMSE"],a.me["Test set","RMSE"],a.dr["Test set","RMSE"],a.na.sa["Test set","RMSE"],a.me.sa["Test set","RMSE"],a.dr.sa["Test set","RMSE"])
MAE1 = c(a.na["Test set","MAE"],a.sn["Test set","MAE"],a.me["Test set","MAE"],a.dr["Test set","MAE"],a.na.sa["Test set","MAE"],a.me.sa["Test set","MAE"],a.dr.sa["Test set","MAE"])
results1 <-data.frame(RMSE1, MAE1, row.names = c("Naive","Seasonal Naive", "Average","Drift","Naive SA", "Average SA","Drift SA"))
colnames(results1) <- c("RMSE","MAE")
results1[order(results1$RMSE),]

################# Smoothing ####################
## Holt's method on seasonally adjusted data
# Linear trend
s.h <- holt(sa.train, h=30)
# Damped trend
s.hd <- holt(sa.train, h=30, damped=TRUE)
# Plot
autoplot(sa)+
  autolayer(s.h, PI=FALSE, series="Holt's Method")+
  autolayer(s.hd,PI=FALSE, series="Holt's with Damped Trend")+
  ggtitle("Seasonally Adjusted Time Series of Median Sale Price \n for Homes in Philadelphia, PA with Smoothing Methods")+
  xlab("Year")+
  ylab("Seasonally Adjusted Median Home Sale Price ($)")

## Holt-Winters
# Additive 
s.hwa <- hw(ts.train,h=30, seasonal="additive")
# Multiplicative 
s.hwm <- hw(ts.train,h=30, seasonal="multiplicative")

## ETS
# (A,Ad,A)
s.ets <- ets(ts.train,model="AAA",damped=TRUE)
summary(s.ets)
s.ets.f <- forecast(s.ets, h=30)
# (A,A,A)
s.ets1 <-ets(ts.train,model="AAA",damped=FALSE)
summary(s.ets1)
s.ets.f1 <- forecast(s.ets1, h=30)

# Accuracy 
a.hwa <-accuracy(s.hwa, ts.test)
a.hwm <-accuracy(s.hwm, ts.test)
a.ets1 <- accuracy(s.ets.f,ts.test)
a.ets2 <- accuracy(s.ets.f1, ts.test)
RMSE2=c(a.na["Test set","RMSE"],a.sn["Test set","RMSE"],a.me["Test set","RMSE"],a.dr["Test set","RMSE"],a.na.sa["Test set","RMSE"],a.me.sa["Test set","RMSE"],a.dr.sa["Test set","RMSE"],a.hwa["Test set","RMSE"],a.hwm["Test set","RMSE"],a.ets1[2,2],a.ets2[2,2])
MAE2 = c(a.na["Test set","MAE"],a.sn["Test set","MAE"],a.me["Test set","MAE"],a.dr["Test set","MAE"],a.na.sa["Test set","MAE"],a.me.sa["Test set","MAE"],a.dr.sa["Test set","MAE"],a.hwa["Test set","MAE"],a.hwm["Test set","MAE"], a.ets1[2,3],a.ets2[2,3])
results2 <-data.frame(RMSE2, MAE2, row.names = c("Naive","Seasonal Naive", "Average","Drift","Naive SA", "Average SA","Drift SA","HW - Additive", "HW-Multiplicative", "ETS(A,Ad,A)","ETS(A,A,A)"))
colnames(results2) <- c("RMSE","MAE")
results2[order(results2$RMSE),]
# Plot
autoplot(ts)+
  #autolayer(s.hwa, PI=FALSE, series="HW - Additive")+
  #autolayer(s.hwm, PI=FALSE,series="HW - Multiplicative")+
  autolayer(s.ets.f, PI=FALSE, series="ETS(A,Ad,A)")+
  autolayer(s.ets.f1, PI=FALSE, series="ETS(A,A,A)")+
  ggtitle("Median Sale Price for Homes in Philadelphia, PA")+
  xlab("Year")+
  ylab("Median Sale Price ($)")

## Check residuals
# HW - multiplicative
checkresiduals(s.hwm)
# HW- Additive
checkresiduals(s.hwa)




################ ARIMA ###################
## Unit Root Test - original series
# KPSS
summary(ur.kpss(ts.train))
ndiffs(ts.train)
# ADF
adf.test(ts)

## Unit Root Test -with first difference
# KPSS
summary(ur.kpss(diff(ts.train)))
# ADF
adf.test(diff(ts.train))

# Plot
autoplot(diff(ts.train))+
  ggtitle("Differenced Series")+
  xlab("Year")+
  ylab("Median Sale Price ($)")

ggtsdisplay(diff(ts.train),lag.max=84)


# AR(12)
fit.ar12 <- Arima(ts.train, order=c(12,1,0))
fit.ar12.f <- forecast(fit.ar12,h=30)
#checkresiduals(fit.ar12)
#summary(fit.ar12)

# MA(6) on seasonality
fit.ma6 <- Arima(ts.train,order=c(0,1,0),seasonal=c(0,0,6))
fit.ma6.f <- forecast(fit.ma6, h=30)
#checkresiduals(fit.ma6)

# ARIMA(12,1,0)(0,1,1)
fit12_1_1 <- Arima(ts.train, order=c(12,1,0), seasonal=c(0,1,1))
fit12_1_1.f <- forecast(fit12_1_1,h=30)
checkresiduals(fit12_1_1)

# Auto arima
fit.auto <- auto.arima(ts.train)
fit.auto.f <- forecast(fit.auto, h=30)
#summary(fit.auto)
checkresiduals(fit.auto)


# Accuracy 
results3 <- data.frame("Model" = c("ARIMA(12,1,0)","ARIMA(0,1,0)(0,0,6)[12]","ARIMA(0,1,1)(0,1,1)[12]","ARIMA(12,1,0)(0,1,1)[12]"),"AIC"=c(AIC(fit.ar12),AIC(fit.ma6),AIC(fit.auto),AIC(fit12_1_1)))
results3[order(results3$AIC),]


# Plot
autoplot(ts)+
  autolayer(forecast(fit.ar12,h=30), PI=FALSE, series="ARIMA(12,1,0)")+
  autolayer(forecast(fit.ma6,h=30), PI=FALSE, series="ARIMA(0,1,0)(0,0,6)[12]")+
  autolayer(forecast(fit.auto,h=30), PI=FALSE, series="ARIMA(0,1,1)(0,1,1)[12]")+
  autolayer(forecast(fit12_1_1,h=30),PI=FALSE, series="ARIMA(12,1,0)(0,1,1)[12]")+
  ggtitle("ARIMA Forecasts of Median Sale Price of 
          Homes in Philadelphia, PA")+
  xlab("Year")+
  ylab("Median Sale Price ($)")

results3


###################### Conclusion #######################
# Accuracy
a.ar12 <-accuracy(fit.ar12.f,ts.test)
a.ma6 <- accuracy(fit.ma6.f,ts.test)
a.12_1_1 <-accuracy(fit12_1_1.f,ts.test)
a.auto <- accuracy(fit.auto.f,ts.test)
RMSE3=c(a.na["Test set","RMSE"],a.sn["Test set","RMSE"],a.me["Test set","RMSE"],a.dr["Test set","RMSE"],a.na.sa["Test set","RMSE"],a.me.sa["Test set","RMSE"],a.dr.sa["Test set","RMSE"],a.hwa["Test set","RMSE"],a.hwm["Test set","RMSE"],a.ets1[2,2],a.ets2[2,2],a.ar12[2,2],a.ma6[2,2],a.12_1_1[2,2],a.auto[2,2])
MAE3 = c(a.na["Test set","MAE"],a.sn["Test set","MAE"],a.me["Test set","MAE"],a.dr["Test set","MAE"],a.na.sa["Test set","MAE"],a.me.sa["Test set","MAE"],a.dr.sa["Test set","MAE"],a.hwa["Test set","MAE"],a.hwm["Test set","MAE"], a.ets1[2,3],a.ets2[2,3],a.ar12[2,3],a.ma6[2,3],a.12_1_1[2,3],a.auto[2,3])
AIC2 = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,AIC(s.ets),AIC(s.ets1),AIC(fit.ar12),AIC(fit.ma6),AIC(fit.auto),AIC(fit12_1_1))
results4 <- data.frame(RMSE3,MAE3,AIC2,row.names = c("Naive","Seasonal Naive", "Average","Drift","Naive SA", "Average SA","Drift SA","HW - Additive", "HW-Multiplicative", "ETS(A,Ad,A)","ETS(A,A,A)","ARIMA(12,1,0)","ARIMA(0,1,0)(0,0,6)[12]","ARIMA(0,1,1)(0,1,1)[12]","ARIMA(12,1,0)(0,1,1)[12]"))
colnames(results4) <- c("RMSE","MAE","AIC")
results4[order(results4$AIC),]

## Cross Validation ##
farima <- function(x, h) {
  forecast(auto.arima(x), h=h)
}
farima1 <- function(x, h) {
  forecast(Arima(x,order=c(12,1,0), seasonal=c(0,1,1)), h=h)
}
far12 <- function(x,h) {
  forecast(Arima(x, order=c(12,1,0)),h=h)
}
fma6 <- function(x,h) {
  forecast(Arima(x, order=c(0,1,0),seasonal=c(0,0,6)),h=h)
}
fets <- function(x,h) {
  forecast(ets(x,model="AAA",damped=TRUE),h=h)
}
fets1 <- function(x,h) {
  forecast(ets(x,model="AAA",damped=FALSE),h=h)
}
e <- tsCV(ts,farima, h=30)
e1 <- tsCV(ts,farima1,h=30)
e2 <- tsCV(ts,far12,h=30)
e3 <- tsCV(ts,fma6, h=30)
e4 <- tsCV(ts, fets, h=30)
e5 <- tsCV(ts, fets1, h=30)

cv <- data.frame("Model"=c("ARIMA(0,1,1)(0,1,1)[12]","ARIMA(12,1,0)(0,1,1)[12]","ARIMA(12,1,0)","ARIMA(0,1,0)(0,0,6)[12]","ETS(A,Ad,A)","ETS(A,A,A)"),"MSE"=c(
  mean(e^2,na.rm=TRUE),
  mean(e1^2,na.rm=TRUE),
  mean(e2^2,na.rm=TRUE),
  mean(e3^2,na.rm=TRUE),
  mean(e4^2,na.rm=TRUE),
  mean(e5^2,na.rm=TRUE)))
cv[order(cv$MSE),]


## PI ##
pi <-data.frame("PI_Width_Model_1"=c(fit.auto.f[["upper"]][,1]-fit.auto.f[["lower"]][,1]),
                "PI_Width_Model_2"=c(fit12_1_1.f[["upper"]][,1]-fit12_1_1.f[["lower"]][,1]),
                "PI_Width_Model_3"=c(fit.ma6.f[["upper"]][,1]-fit.ma6.f[["lower"]][,1]))
pi 
colSums(pi)

# Plot
autoplot(ts)+
  autolayer(forecast(fit12_1_1,h=30), series="ARIMA(12,1,0)(0,1,1)[12]")+
  ggtitle("ARIMA Forecasts of Median Sale Price of 
          Homes in Philadelphia, PA")+
  xlab("Year")+
  ylab("Median Sale Price ($)")