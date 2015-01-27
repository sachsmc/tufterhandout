## ----asidecode----------------------------------------------------------------
rnorm(1)

## ----fig1, tidy = TRUE, fig.width = 4, fig.height = 4, echo = TRUE, marginfigure = TRUE, fig.cap = "This is a marginfigure"----
library(ggplot2)
ggplot(mtcars, aes(y = mpg, x = wt)) + geom_point() + stat_smooth(method = "lm")

## ----fig2, tidy = TRUE, fig.width = 22, fig.height = 3, fig.cap = "Full-width figure", fig.star = TRUE----
ggplot(faithful, aes(y = eruptions, x = waiting)) + geom_point() + stat_smooth(method = "loess")

## ----fig3, tidy = TRUE, fig.width = 8, fig.height = 3, fig.cap = "Normal figure with caption in the margin"----
ggplot(faithful, aes(x = eruptions)) + geom_histogram(binwidth = .1)

