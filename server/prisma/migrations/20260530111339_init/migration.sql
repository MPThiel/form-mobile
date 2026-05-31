-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "authProvider" TEXT NOT NULL,
    "subscriptionTier" TEXT NOT NULL DEFAULT 'free',
    "subscriptionExpiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Profile" (
    "userId" TEXT NOT NULL,
    "currentWeight" DOUBLE PRECISION NOT NULL,
    "targetWeight" DOUBLE PRECISION NOT NULL,
    "age" INTEGER NOT NULL,
    "trainingHistory" TEXT NOT NULL,
    "goals" JSONB NOT NULL,
    "mood" INTEGER NOT NULL,
    "energy" INTEGER NOT NULL,
    "physicalNotes" TEXT,
    "nutritionStyle" TEXT NOT NULL,
    "dailyCalorieTarget" INTEGER NOT NULL,
    "weeklyRunKmTarget" DOUBLE PRECISION NOT NULL,
    "weeklyWorkoutDays" INTEGER NOT NULL,
    "setupDate" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Profile_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "DailyLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "weight" DOUBLE PRECISION,

    CONSTRAINT "DailyLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Meal" (
    "id" TEXT NOT NULL,
    "dailyLogId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "calories" INTEGER NOT NULL,
    "protein" INTEGER NOT NULL,
    "carbs" INTEGER NOT NULL,
    "fat" INTEGER NOT NULL,
    "photoUrl" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Meal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Run" (
    "id" TEXT NOT NULL,
    "dailyLogId" TEXT NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "paceSecPerKm" INTEGER NOT NULL,
    "source" TEXT NOT NULL,
    "externalId" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Run_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Workout" (
    "id" TEXT NOT NULL,
    "dailyLogId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "durationMin" INTEGER NOT NULL,
    "difficulty" INTEGER NOT NULL,
    "notes" TEXT,
    "source" TEXT NOT NULL,
    "externalId" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Workout_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StravaConnection" (
    "userId" TEXT NOT NULL,
    "athleteId" BIGINT NOT NULL,
    "accessToken" TEXT NOT NULL,
    "refreshToken" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "connectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StravaConnection_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "WeekPlan" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "weekStart" DATE NOT NULL,
    "approved" BOOLEAN NOT NULL DEFAULT false,
    "proposedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "days" JSONB NOT NULL,

    CONSTRAINT "WeekPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatMessage" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatMessage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "DailyLog_userId_date_idx" ON "DailyLog"("userId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "DailyLog_userId_date_key" ON "DailyLog"("userId", "date");

-- CreateIndex
CREATE INDEX "Meal_dailyLogId_idx" ON "Meal"("dailyLogId");

-- CreateIndex
CREATE INDEX "Run_dailyLogId_idx" ON "Run"("dailyLogId");

-- CreateIndex
CREATE UNIQUE INDEX "Run_source_externalId_key" ON "Run"("source", "externalId");

-- CreateIndex
CREATE INDEX "Workout_dailyLogId_idx" ON "Workout"("dailyLogId");

-- CreateIndex
CREATE UNIQUE INDEX "Workout_source_externalId_key" ON "Workout"("source", "externalId");

-- CreateIndex
CREATE UNIQUE INDEX "StravaConnection_athleteId_key" ON "StravaConnection"("athleteId");

-- CreateIndex
CREATE UNIQUE INDEX "WeekPlan_userId_weekStart_key" ON "WeekPlan"("userId", "weekStart");

-- CreateIndex
CREATE INDEX "ChatMessage_userId_createdAt_idx" ON "ChatMessage"("userId", "createdAt");

-- AddForeignKey
ALTER TABLE "Profile" ADD CONSTRAINT "Profile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DailyLog" ADD CONSTRAINT "DailyLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Meal" ADD CONSTRAINT "Meal_dailyLogId_fkey" FOREIGN KEY ("dailyLogId") REFERENCES "DailyLog"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Run" ADD CONSTRAINT "Run_dailyLogId_fkey" FOREIGN KEY ("dailyLogId") REFERENCES "DailyLog"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Workout" ADD CONSTRAINT "Workout_dailyLogId_fkey" FOREIGN KEY ("dailyLogId") REFERENCES "DailyLog"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StravaConnection" ADD CONSTRAINT "StravaConnection_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WeekPlan" ADD CONSTRAINT "WeekPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
