public with sharing class ProjectPlanningController {
    
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

        for (Integer i = 0; i < 5; i++) {
            Date weekStart = currentWeekStart.addDays(i * 7);
            Date weekEnd = weekStart.addDays(6);

            CalendarWeek cw = new CalendarWeek(
                getISOYear(weekStart),
                getISOWeekNumber(weekStart),
                weekStart,
                weekEnd
            );
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
        public CalendarWeek(Integer year, Integer weekNumber, Date startDate, Date endDate){
            this.year = year;
            this.weekNumber = weekNumber;
            this.startDate = startDate;
            this.endDate = endDate;
            this.Id = this.year + '-W' + String.valueOf(this.weekNumber);
        }
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