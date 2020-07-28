# download given data set 
install.packages("data.table")
library(data.table)
install.packages("reshape2")
library(reshape2)
destfile <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(destfile, "UCIHAR.zip"))
unzip(zipfile = "UCIHAR.zip")

# load activity labels and features from data set 
activityLabels <- fread(file.path(destfile, "UCI HAR Dataset/activity_labels.txt"), 
                        col.names = c("classLabels", "activityName"))
features <- fread(file.path(destfile, "UCI HAR Dataset/features.txt"),
                  col.names = c("index", "featureNames"))

# get index of mean and standard deviation for measurements 
featuresWanted <- grep("(mean|std)\\(\\)", features[, featureNames])

# subset features by wanted measurements (mean & standard deviation)
measurements <- features[featuresWanted, featureNames]

# remove all () 
measurements <- gsub('[()]','', measurements) 

# load train data set and subset only wanted features
train <- fread(file.path(destfile, "UCI HAR Dataset/train/X_train.txt"))[, featuresWanted, with = FALSE]

# change column names in train data table to measurements 
data.table::setnames(train, colnames(train), measurements)

# load Train Activities & Train Subjects and
trainActivities <- fread(file.path(destfile, "UCI HAR Dataset/train/y_train.txt"),
                         col.names = c("Activity"))
trainSubjects <- fread(file.path(destfile, "UCI HAR Dataset/train/subject_train.txt"), 
                       col.names = c("SubjectNum"))

# Combine to form overall cleaned train data set.
train <- cbind(trainSubjects, trainActivities, train)

# load test data set, subset according to wanted feaatures
# and set column names to measurements
test <- fread(file.path(destfile, "UCI HAR Dataset/test/X_test.txt"))[, featuresWanted, with = FALSE]

# set column names to values of measurements
data.table:setnames(test, colnames(test), measurements)

# load test activities and test subjects
testActivities <- fread(file.path(destfile, "UCI HAR Dataset/test/y_test.txt"),
                        col.names = c("Activity"))
testSubjects <- fread(file.path(destfile, "UCI HAR Dataset/test/subject_test.txt"),
                      col.names = c("SubjectNum"))

# combine 3 data sets to form cleaned test data table
test <- cbind(testSubjects, testActivities, test)

# merge train and test data sets 
combinedData <- rbind(train, test, fill = TRUE)

# convert classLabels to activityName to factors
combinedData[["Activity"]] <- factor(combinedData[, Activity], 
                                   levels = activityLabels[["classLabels"]],
                                   labels = activityLabels[["activityName"]])

# set Subject Number as factors 
combinedData[["SujectNum"]] <- as.factor(combinedData[, SubjectNum])

# Melt data using reshape2 package
meltedData <- melt(data = combinedData, id = c("SubjectNum", "Activity"))

# Tidy data set with average of each variable for each activity and each subject using reshape2 package
tidyData <- dcast(data = meltedData, SubjectNum + Activity ~ variable, fun.aggregate = mean)

data.table::fwrite(x = combinedData, file = "tidyData.txt", quote = FALSE)

# Generate code book
install.packages("codebook")
library(codebook)
