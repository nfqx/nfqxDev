public with sharing class ProjectPlanningController {
    
    @AuraEnabled(cacheable=false)
    public static List<CalendarWeek> retrieveCurrentWeeks(){
        List<CalendarWeek> returnList = new List<CalendarWeek>();
        return returnList; 
    }
    @AuraEnabled(cacheable=false)
    public static List<EmployeeWithProjects> retrieveEmployeeData(List<CalendarWeek> weeks){
        List<EmployeeWithProjects> returnList = new List<EmployeeWithProjects>();
        return returnList; 
    }
    @AuraEnabled(cacheable=false)
    public static List<ProjectWithEmployees> retrieveCalendarData(List<CalendarWeek> weeks){
        List<ProjectWithEmployees> returnList = new List<ProjectWithEmployees>();
        return returnList; 
    }
    public class CalendarWeek{
        @AuraEnabled public Integer year;
        @AuraEnabled public Integer weekNumber;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String Id;
    }
    public class EmployeeWithProjects{
        @AuraEnabled public String employeeName;
        @AuraEnabled public String Id;
        @AuraEnabled public List<EmployeeProject> projects;
    }
    public class EmployeeProject{
        @AuraEnabled public String projectName;
        @AuraEnabled public String Id;
        @AuraEnabled public String staffedEmployeeId;
        @AuraEnabled public List<Planning> plannings;
    }
    public class Planning{
        @AuraEnabled public Date planningDate;
        @AuraEnabled public String Id;
        @AuraEnabled public CalendarWeek calendarWeek;
    }
    public class ProjectWithEmployees{
        @AuraEnabled public String projectName;
        @AuraEnabled public String Id;
        @AuraEnabled public List<EmployeeProject> projects;
    }
    public class ProjectEmployee{
        @AuraEnabled public String employeeName;
        @AuraEnabled public String Id;
        @AuraEnabled public String staffedEmployeeId;
        @AuraEnabled public List<Planning> plannings;
    }
}