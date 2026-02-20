@IsTest
private class ProjectPlanningControllerTest {

    private static void setupTestData() {
        Account acc = new Account(Name = 'test');
        insert acc;

        Role__c role = new Role__c(
            Code__c = '123',
            DefaultPricePerHour__c = 100,
            Name = 'Test'
        );
        insert role;

        // Employee
        Employee__c emp = new Employee__c(
            User__c = UserInfo.getUserId(),
            Code__c = '123',
            OnboardingDate__c = Date.today()
        );
        insert emp;

        // Project
        Project__c proj = new Project__c(
            Name = 'Test Project',
            ProjectStatus__c = 'In Progress',
            Code__c = '123',
            Account__c = acc.Id
        );
        insert proj;

        // Staffed Employee
        StaffedEmployee__c se = new StaffedEmployee__c(
            Employee__c = emp.Id,
            Project__c = proj.Id,
            Role__c = role.Id,
            PricePerHour__c = 100
        );
        insert se;

        // Planning record
        Planning__c pl = new Planning__c(
            Employee__c = emp.Id,
            Project__c = proj.Id,
            Date__c = Date.today(),
            TimeHours__c = 8
        );
        insert pl;
    }

    @IsTest
    static void testRetrieveCurrentWeeks() {
        Test.startTest();
        List<ProjectPlanningController.CalendarWeek> weeks =
            ProjectPlanningController.retrieveCurrentWeeks();
        Test.stopTest();

        System.assertNotEquals(0, weeks.size());
        System.assertEquals(ProjectPlanningController.WEEKS_UPFRONT + 1, weeks.size());
        System.assertNotEquals(null, weeks[0].startDate);
    }

    @IsTest
    static void testSaveData() {
        setupTestData();
        Role__c role = new Role__c(
            Code__c = '1234',
            DefaultPricePerHour__c = 100,
            Name = 'Tester'
        );
        insert role;

        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Planning__c existingPlan = [SELECT Id FROM Planning__c LIMIT 1];

        // Build wrapper
        ProjectPlanningController.SaveRecordsWrapper wrapper =
            new ProjectPlanningController.SaveRecordsWrapper();

        wrapper.newStaffings = new List<ProjectPlanningController.StaffingWrapper>();
        wrapper.updatedPlannings = new List<ProjectPlanningController.PlanningWrapper>();
        wrapper.insertedPlannings = new List<ProjectPlanningController.PlanningWrapperAlt>();

        // New staffing
        ProjectPlanningController.StaffingWrapper sw =
            new ProjectPlanningController.StaffingWrapper();
        sw.employeeId = emp.Id;
        sw.projectId = proj.Id;
        sw.projectRole = role.Id;
        sw.hourlyRate = 50;
        wrapper.newStaffings.add(sw);

        // Update planning
        ProjectPlanningController.PlanningWrapper pw =
            new ProjectPlanningController.PlanningWrapper();
        pw.Id = existingPlan.Id;
        pw.hours = 10;
        wrapper.updatedPlannings.add(pw);

        // Insert planning
        ProjectPlanningController.PlanningWrapperAlt pwa =
            new ProjectPlanningController.PlanningWrapperAlt();
        pwa.employeeId = emp.Id;
        pwa.projectId = proj.Id;
        pwa.calendarDate = Date.today().addDays(3);
        pwa.hours = 6;
        wrapper.insertedPlannings.add(pwa);

        String jsonData = JSON.serialize(wrapper);

        Test.startTest();
        Boolean result = ProjectPlanningController.saveData(jsonData);
        Test.stopTest();

        System.assertEquals(true, result);

        System.assertEquals(2,
            [SELECT COUNT() FROM Planning__c WHERE Project__c = :proj.Id]);

        System.assert(
            [SELECT COUNT() FROM StaffedEmployee__c WHERE Role__r.Name = 'Test'] > 0
        );
    }

    @IsTest
    static void testRetrieveEmployeeData() {
        setupTestData();

        List<ProjectPlanningController.CalendarWeek> weeks =
            ProjectPlanningController.retrieveCurrentWeeks();

        Test.startTest();
        List<ProjectPlanningController.EmployeeWithProjects> result =
            ProjectPlanningController.retrieveEmployeeData(weeks);
        Test.stopTest();

        System.assertNotEquals(0, result.size());
        System.assertNotEquals(0, result[0].projects.size());
    }

    @IsTest
    static void testRetrieveCalendarData() {
        setupTestData();

        List<ProjectPlanningController.CalendarWeek> weeks =
            ProjectPlanningController.retrieveCurrentWeeks();

        Test.startTest();
        List<ProjectPlanningController.ProjectWithEmployees> result =
            ProjectPlanningController.retrieveCalendarData(weeks);
        Test.stopTest();

        System.assertNotEquals(0, result.size());
        System.assertNotEquals(0, result[0].employees.size());
    }
}