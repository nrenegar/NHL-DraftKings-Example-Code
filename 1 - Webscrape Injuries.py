#########################################################################
#########################################################################
#NHL Draftking Example Injuries Webscraping
#Nicholas Renegar - Dec 1, 2019

#########################################################################
#########################################################################

# coding: utf-8

from selenium import webdriver
import pandas as pd

#Initialize chromedriver
path_to_chromedriver = '/Applications/chromedriver'
browser = webdriver.Chrome(executable_path = path_to_chromedriver)


##################################################
########CBS Sports injury report##################
##################################################
url ='https://www.cbssports.com/nhl/injuries'
browser.get(url)

#Get all names from injury report
a = browser.find_elements_by_class_name('CellPlayerName--long')

browser.switch_to_default_content()

df = pd.DataFrame()

for tr in a:
    name= tr.get_attribute("innerText")
    df = df.append(pd.Series(name), ignore_index=True)
    
df.columns = ["Name"]
df.to_csv('./Injuries_CBS.csv',index=False)
browser.close()
