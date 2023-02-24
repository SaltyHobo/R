# Disclosure 1: This is similar to my previous attempt in Java to source information from SEC filings. You can find my Java version here: https://github.com/SaltyHobo/Java/tree/main/JavaFinReportBuilder .
# Disclosure 2: Out of curiosity on the effectiveness of ChatGPT, I consulted with the AI chat to build this file. If you find any errors or methods of improvement, please contact me!

# I am attempting to retrieve SEC filings of publicly traded companies, which I can later use for financial analysis.
# This first file is to retrieve the financial filing from the SEC's EDGAR database, and create an Excel file from the information.

# Load necessary packages
library(xlsx)
library(RCurl)
library(XML)

# Prompt the user for a company name or ticker symbol
company <- readline(prompt = "Enter a company name or ticker symbol: ")

# Set the URL for the SEC's EDGAR database
url <- "https://www.sec.gov/cgi-bin/browse-edgar"

# Send a POST request to the SEC's EDGAR database to search for the company filings
params <- list(
    action = "getcompany",
    output = "xml",
    count = "30",
    company = company
)
raw.data <- postForm(url, .params = params)

# Parse the XML data
parsed.data <- xmlParse(raw.data)

# Extract the CIK number for the company
cik <- xmlValue(parsed.data[["//CIK"]])

# Set parameters for SEC Edgar search for the company's quarterly filings
params <- list(
    action = "getcompany",
    CIK = cik,
    type = "10-Q",
    output = "xml",
    count = "30"
)

# Send GET request to SEC Edgar website and parse XML data
raw.data <- getURL(url, .params = params)
parsed.data <- xmlParse(raw.data)

# Extract information for each quarterly report
reports <- getNodeSet(parsed.data, "//results/filing")

# Create an empty data frame to store financial information
financials <- data.frame()

# Loop through each quarterly report and extract balance sheet data
for (i in 1:length(reports)) {
    # Extract the link to the HTML filing
    filing.url <- xmlValue(reports[[i]]$filingHREF)

    # Extract the balance sheet data from the HTML filing
    balance.sheet <- readHTMLTable(filing.url, which = 1, header = TRUE)
    total.assets <- balance.sheet[grep("Total Assets", balance.sheet$`Balance Sheet`), 2]

    # Add the balance sheet data to the financials data frame
    financials <- rbind(financials, total.assets)
}

# Set the column name for the financials data frame
colnames(financials) <- "Total Assets"

# Create a new Excel workbook and write the financials data to a sheet
wb <- createWorkbook()
sheet <- createSheet(wb, sheetName = "Financials")
addDataFrame(financials, sheet = sheet)

# Save the Excel workbook to a file
filename <- paste0(company, " Financials.xlsx")
saveWorkbook(wb, file = filename)
