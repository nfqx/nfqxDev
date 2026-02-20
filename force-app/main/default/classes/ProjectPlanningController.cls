public with sharing class ProjectPlanningController {
    
    public static Integer WEEKS_UPFRONT = 4;

    @AuraEnabled(cacheable=false)
    public static List<CalendarWeek> retrieveCurrentWeeks(){
        List<CalendarWeek> returnList = new List<CalendarWeek>();

        Date today = Date.today();

        // Get Monday of the current week (ISO: Monday = start)
        Date currentWeekStart = today.toStartOfWeek().addDays(1);

        // If today is Sunday, adjust back 6 days
        if (today.toStartOfWeek() == today) {
            currentWeekStart = today.addDays(-6);
        }

        for (Integer i = 0; i <= WEEKS_UPFRONT; i++) {
            Date weekStart = currentWeekStart.addDays(i * 7);
            CalendarWeek cw = new CalendarWeek(weekStart);
            returnList.add(cw);
        }

        return returnList;
    }

    /*
     * ISO week number calculation
     */
    private static Integer getISOWeekNumber(Date d) {
        // Shift date to Thursday of same week (ISO rule)
        Integer dayOfWeek = d.toStartOfWeek().daysBetween(d) + 1; // 1=Sun ... 7=Sat
        Integer isoDay = (dayOfWeek == 1) ? 7 : dayOfWeek - 1;     // Convert to ISO Mon=1

        Date thursday = d.addDays(4 - isoDay);
        Date yearStart = Date.newInstance(thursday.year(), 1, 1);

        return ((yearStart.daysBetween(thursday)) / 7) + 1;
    }

    /*
     * ISO year (handles year overlap weeks)
     */
    private static Integer getISOYear(Date d) {
        Integer dayOfWeek = d.toStartOfWeek().daysBetween(d) + 1;
        Integer isoDay = (dayOfWeek == 1) ? 7 : dayOfWeek - 1;

        Date thursday = d.addDays(4 - isoDay);
        return thursday.year();
    }

    @AuraEnabled(cacheable=false)
    public static Boolean saveData(String dataString){
        SaveRecordsWrapper data = (SaveRecordsWrapper) JSON.deserialize(dataString, SaveRecordsWrapper.class);
        List<StaffedEmployee__c> staffedEmployeeInsert = new List<StaffedEmployee__c>();
        List<Planning__c> planningsUpsert = new List<Planning__c>();

        for(StaffingWrapper staffing : data.newStaffings){
            StaffedEmployee__c se = new StaffedEmployee__c();
            se.Employee__c = staffing.employeeId;
            se.Project__c = staffing.projectId;
            se.Role__c = staffing.projectRole;
            se.PricePerHour__c = staffing.hourlyRate;
            staffedEmployeeInsert.add(se);
        }

        for(PlanningWrapper planning : data.updatedPlannings){
            Planning__c pl = new Planning__c();
            pl.Id = planning.Id;
            pl.TimeHours__c = planning.hours;
            planningsUpsert.add(pl);
        }

        for(PlanningWrapperAlt planning : data.insertedPlannings){
            Planning__c pl = new Planning__c();
            pl.Employee__c = planning.employeeId;
            pl.Project__c = planning.projectId;
            pl.Date__c = planning.calendarDate;
            pl.TimeHours__c = planning.hours;
            planningsUpsert.add(pl);
        }

        if(!staffedEmployeeInsert.isEmpty()){
            insert staffedEmployeeInsert;
        }
        if(!planningsUpsert.isEmpty()){
            upsert planningsUpsert;
        }
        return true;
    }

    @AuraEnabled(cacheable=false)
    public static List<EmployeeWithProjects> retrieveEmployeeData(List<CalendarWeek> weeks){
        Date minDate = Date.today();
        Date maxDate = Date.today();
        for(CalendarWeek cw : weeks){
            if(cw.startDate < minDate){
                minDate = cw.startDate;
            }
            if(cw.endDate > maxDate){
                maxDate = cw.endDate;
            }
        }
        Map<Id, EmployeeWithProjects> returnMap = new Map<Id, EmployeeWithProjects>();
        for(Employee__c employee : [SELECT Id, User__r.Name, (SELECT Id, Role__c, PricePerHour__c, Project__c, Project__r.Name FROM ProjectRoles__r WHERE ProjectStatus__c != 'Terminated' AND ProjectStatus__c != 'Completed'), (SELECT Id, Employee__c, TimeHours__c, CalendarYear__c, CalendarWeek__c, Date__c FROM Plannings__r WHERE Date__c >= : minDate AND Date__c <= : maxDate ORDER BY Date__c) FROM Employee__c WHERE Active__c = TRUE]){
            EmployeeWithProjects ewp = returnMap.containsKey(employee.Id) ? returnMap.get(employee.Id) : new EmployeeWithProjects(employee.User__r.Name, employee.Id);
            for(StaffedEmployee__c projectRole : employee.ProjectRoles__r){
                ewp.projectsMap.put(projectRole.Project__c, new EmployeeProject(projectRole.Project__r.Name, projectRole.Project__c, projectRole.Role__c, projectRole.PricePerHour__c, projectRole.Id));
            }
            for(Planning__c planning : employee.Plannings__r){
                if(ewp.projectsMap.containsKey(planning.Project__c)){
                    ewp.projectsMap.get(planning.Project__c).plannings.add(new Planning(planning.Date__c, planning.Id));
                }
            }
            returnMap.put(employee.Id, ewp);
        }
        return returnMap.values(); 
    }
    @AuraEnabled(cacheable=false)
    public static List<ProjectWithEmployees> retrieveCalendarData(List<CalendarWeek> weeks){
        Date minDate = Date.today();
        Date maxDate = Date.today();
        for(CalendarWeek cw : weeks){
            if(cw.startDate < minDate){
                minDate = cw.startDate;
            }
            if(cw.endDate > maxDate){
                maxDate = cw.endDate;
            }
        }
        Map<Id, ProjectWithEmployees> returnMap = new Map<Id, ProjectWithEmployees>();
        for(Project__c project : [SELECT Id, Name, (SELECT Id, Role__c, PricePerHour__c, Employee__c, Employee__r.User__r.Name FROM ProjectRoles__r WHERE Employee__r.Active__c = TRUE), (SELECT Id, Employee__c, TimeHours__c, CalendarYear__c, CalendarWeek__c, Date__c FROM Plannings__r WHERE Date__c >= : minDate AND Date__c <= : maxDate ORDER BY Date__c) FROM Project__c WHERE ProjectStatus__c != 'Terminated' AND ProjectStatus__c != 'Completed']){
            ProjectWithEmployees pwe = returnMap.containsKey(project.Id) ? returnMap.get(project.Id) : new ProjectWithEmployees(project.Name, project.Id);
            for(StaffedEmployee__c projectRole : project.ProjectRoles__r){
                pwe.employeesMap.put(projectRole.Employee__c, new ProjectEmployee(projectRole.Employee__r.User__r.Name, projectRole.Employee__c, projectRole.Role__c, projectRole.PricePerHour__c, projectRole.Id));
            }
            for(Planning__c planning : project.Plannings__r){
                if(pwe.employeesMap.containsKey(planning.Employee__c)){
                    pwe.employeesMap.get(planning.Employee__c).plannings.add(new Planning(planning.Date__c, planning.Id));
                }
            }
            returnMap.put(project.Id, pwe);
        }
        return returnMap.values(); 
    }
    public class CalendarWeek{
        @AuraEnabled public Integer year;
        @AuraEnabled public Integer weekNumber;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String Id;
        public CalendarWeek(Date weekStart){
            this.year = getISOYear(weekStart);
            this.weekNumber = getISOWeekNumber(weekStart);
            this.startDate = weekStart;
            this.endDate = weekStart.addDays(6);
            this.Id = this.year + '-W' + String.valueOf(this.weekNumber);
        }
    }
    public class EmployeeWithProjects{
        @AuraEnabled public String employeeName;
        @AuraEnabled public String Id;
        @AuraEnabled public Map<Id, EmployeeProject> projectsMap;
        @AuraEnabled public List<EmployeeProject> projects {
            get{
                return this.projectsMap.values();
            }
            private set; 
        }
        public EmployeeWithProjects(String employeeName, String Id){
            this.employeeName = employeeName;
            this.Id = Id;
            this.projectsMap = new Map<Id, EmployeeProject>();
        }
    }
    public class EmployeeProject{
        @AuraEnabled public String projectName;
        @AuraEnabled public String Id;
        @AuraEnabled public String role;
        @AuraEnabled public Decimal pricePerHour;
        @AuraEnabled public String staffedEmployeeId;
        @AuraEnabled public List<Planning> plannings;
        public EmployeeProject(String projectName, String Id, String role, Decimal pricePerHour, String staffedEmployeeId){
            this.projectName = projectName;
            this.Id = Id;
            this.role = role;
            this.pricePerHour = pricePerHour;
            this.staffedEmployeeId = staffedEmployeeId;
            this.plannings = new List<Planning>();
        }
    }
    public class Planning{
        @AuraEnabled public Date planningDate;
        @AuraEnabled public String Id;
        @AuraEnabled public CalendarWeek calendarWeek;
        public Planning(Date planningDate, String Id){
            this.planningDate = planningDate;
            this.Id = Id;            
            Date currentWeekStart = planningDate.toStartOfWeek().addDays(1);
            // If today is Sunday, adjust back 6 days
            if (planningDate.toStartOfWeek() == planningDate) {
                currentWeekStart = planningDate.addDays(-6);
            }
            this.calendarWeek = new CalendarWeek(currentWeekStart);
        }
    }
    public class ProjectWithEmployees{
        @AuraEnabled public String projectName;
        @AuraEnabled public String Id;
        @AuraEnabled public Map<Id, ProjectEmployee> employeesMap;
        @AuraEnabled public List<ProjectEmployee> employees {
            get{
                return this.employeesMap.values();
            }
            private set; 
        }
        public ProjectWithEmployees(String projectName, String Id){
            this.projectName = projectName;
            this.Id = Id;
            this.employeesMap = new Map<Id, ProjectEmployee>();
        }
    }
    public class ProjectEmployee{
        @AuraEnabled public String employeeName;
        @AuraEnabled public String Id;
        @AuraEnabled public String role;
        @AuraEnabled public Decimal pricePerHour;
        @AuraEnabled public String staffedEmployeeId;
        @AuraEnabled public List<Planning> plannings;
        public ProjectEmployee(String employeeName, String Id, String role, Decimal pricePerHour, String staffedEmployeeId){
            this.employeeName = employeeName;
            this.Id = Id;
            this.role = role;
            this.pricePerHour = pricePerHour;
            this.staffedEmployeeId = staffedEmployeeId;
            this.plannings = new List<Planning>();
        }
    }
    public class SaveRecordsWrapper{
        @AuraEnabled public List<StaffingWrapper> newStaffings;
        @AuraEnabled public List<PlanningWrapper> updatedPlannings;
        @AuraEnabled public List<PlanningWrapperAlt> insertedPlannings;
    }
    public class StaffingWrapper{
        @AuraEnabled public String projectId;
        @AuraEnabled public String employeeId;
        @AuraEnabled public String projectRole;
        @AuraEnabled public Decimal hourlyRate;
    }
    public class PlanningWrapper{
        @AuraEnabled public String Id;
        @AuraEnabled public Decimal hours;
    }
    public class PlanningWrapperAlt{
        @AuraEnabled public String projectId;
        @AuraEnabled public String employeeId;
        @AuraEnabled public Date calendarDate;
        @AuraEnabled public Decimal hours;
    }
}