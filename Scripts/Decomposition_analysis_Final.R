#McCary and Schmitz functional traits analysis
#1 March 2021

#=======Litter decomposition==========

#===load libraries======
library(ggplot2)
library(metafor)
library(plyr)
library(lme4)
library(car)
library(dplyr)
library(tidyverse)
library(broom)
library(Rmisc)

#=====import data======
#relative pathname
meta <- file.path(".", "Data", "Decomposition_Data.csv")
print(meta)

#import data
decomp <- read_csv(meta)%>% ##not enough leaf piercers in data set
           drop_na(Std.dev.control)

#Calculate log Response Ratio
decomp.es<-escalc(measure="ROM",
            m1i= Mean.experimental, m2i=Mean.control,
            sd1i=Std.dev.experimental, sd2i=Std.dev.control,
            n1i=SS.experimental, n2i= SS.control, 
            data=decomp,
            var.names=c("LRR","LRR_var"),digits=4)

##to remove outliers for portion decomposed (Ploss > 3 SD)
isnt_out_mad <- function(x, thres = 3, na.rm = TRUE) {
  abs(x - median(x, na.rm = na.rm)) <= thres * mad(x, na.rm = na.rm)
}

lit <- 
  decomp.es%>%
  mutate(Outlier = isnt_out_mad(decomp.es$LRR))%>%
  filter(Outlier == "TRUE")

##Number of observations per trait
lit%>%
  group_by(Trait)%>%
  tally()


#==========Random-effects model=================
mod0<-rma(yi=LRR,vi=LRR_var, data=lit)
summary(mod0)

#==========Mixed-effects model==================
mod1<-rma.mv(yi=LRR,V=LRR_var, mods=~factor(Trait)-1, random = list(~1|ES.ID, ~1|StudyID),
             struct="CS",method="REML",digits=4,level = 95, 
             data=lit)
summary(mod1)

#===========Model fit diagnostics===============
par(mfrow=c(1,1)) ## set the plot matrix

##qq norm plots
qqPlot(residuals.rma(mod1), xlab="Theoretical Quantiles", ylab = "Sample Quantiles", line = "quartiles", col.lines = "black", grid = FALSE)

##residual vs fitted plot
plot(fitted.rma(mod1), residuals.rma(mod1), xlab = "Fitted Residuals", ylab = "Residuals") #residuals vs fitted
abline(h=0)

#==========Publication bias analyses====================
#Trim and fill method
res <- rma(LRR, LRR_var, data = lit, method = "FE")
trimfill(res)
funnel(res, legend = TRUE, size =4 )

#Rosenthal's fail-safe number
fsn(LRR, LRR_var, data = lit, type = "Rosenthal")

#=============Forest plots==============================
summary(mod1)
y<-summary(mod1)$b
ci_l<-summary(mod1)$ci.lb
ci_h<-summary(mod1)$ci.ub

fg1<-as.data.frame(cbind(y, ci_l, ci_h))%>%
  add_column(Trait = c("Ambush hunters", "Bioturbators", 
                       "Detritus grazers", "Detritus shredders",
                       "Hunting predators", "Leaf chewers", "Leaf piercers",
                       "Macro-invertebrates", "Micro-invertebrates"))%>%
  add_column(Function = c("Predators", "Decomposers",
                          "Decomposers", "Decomposers",
                          "Predators", "Herbivores", "Herbivores",
                          "Body size", "Body size"))

#ggplot function
p1<- fg1%>%
  mutate(Trait = fct_relevel(Trait,
                             "Micro-invertebrates",
                             "Macro-invertebrates",
                             "Detritus grazers",
                             "Detritus shredders",
                             "Bioturbators",
                             "Leaf chewers",
                             "Leaf piercers",
                             "Hunting predators",
                             "Ambush hunters"))%>%
  ggplot(aes(x=Trait, y=V1, ymin=ci_l, ymax=ci_h, color = Function)) + 
  geom_errorbar(aes(ymin=ci_l, ymax=ci_h), size=1.5, width=0.2)+
  geom_point(shape=19, size=4)+
  geom_pointrange()+
  coord_flip(ylim=c(-0.5, 0.5))+
  scale_color_manual(values=c("grey65", "chocolate4", "green3", "Black"))+
  xlab(NULL) +
  ylab(NULL)+
  geom_hline(aes(yintercept=0))+
  theme(axis.text = element_text(size=12, face="bold", colour = "black"),
        axis.ticks = element_line(colour = "black"),
        panel.background = element_rect(fill= "white"),
        legend.position = "none",
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(fill = NA, colour = "black", size = 1.5))




