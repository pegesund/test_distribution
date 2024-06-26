defmodule Feeder do
  @moduledoc """
  Documentation for `Feeder`.
  """

defmodule AppearenceTemp do
  defstruct pupil: "", topic: "", date: nil, day_in_year: 0
end


defmodule Appearence do
  defstruct pupil: "", topic: "", date: nil, time_total: 45, absence_valid: 0, absence_invalid: 0, full_day: False, class_id: 0, school_id: 0
end

  def create_topics do
    # topics should be in the database
    # default every hour to 4 as we do not have number of hours for each topic
    %{
      "english" => 6,
      "history" => 5,
      "pysics" => 5,
      "gymnastics" => 5,
      "math" => 3,
      "programming" => 5,
      "french" => 3,
      "german" => 2,
      "pshycology" => 5,
      "biology" => 4,
      "chemistry" => 6,
      "geography" => 3,
      "music" => 3,
      "art" => 2,
      "drama" => 1,
    }
  end

  def create_pupils(number_of_pupils_in_class) do
    for i <- 1..number_of_pupils_in_class, do: "pupil_#{i}"
  end

  defp pick_topics_for_pupil_recursive(hours_accumulator, picked_topics, _topics, minimum_number_of_hours) when hours_accumulator >= minimum_number_of_hours, do: {picked_topics, hours_accumulator}

  defp pick_topics_for_pupil_recursive(hours_accumulator, picked_topics, topics, minimum_number_of_hours) do
    {topic, hours} = Enum.random(topics)
    if Enum.member?(picked_topics, topic) do
      pick_topics_for_pupil_recursive(hours_accumulator, picked_topics, topics, minimum_number_of_hours)
    else
      hours_accumulator = hours_accumulator + hours
      pick_topics_for_pupil_recursive(hours_accumulator, [topic | picked_topics], topics, minimum_number_of_hours)
    end
  end

  def pick_topics_for_pupils(pupils, topics, minimum_number_of_hours) do
    info = Enum.map(pupils, fn pupil -> {pupil, pick_topics_for_pupil_recursive(0, [], topics, minimum_number_of_hours)} end)
    Enum.into(info, %{})
  end



  def create_calendar_recursive(calendar_so_far, topics_remaining_hours, hours_so_far, max_hours_per_day, day_number) do
    if day_number == 0 do
      calendar_so_far
    else
      if max_hours_per_day <= hours_so_far do
        create_calendar_recursive(calendar_so_far, topics_remaining_hours, 0, max_hours_per_day, day_number - 1)
      else
        {topic, topic_remaining_hours} = Enum.random(topics_remaining_hours)
        topics_remaining_hours = if topic_remaining_hours == 0 do
          Map.delete(topics_remaining_hours, topic)
        else
          Map.put(topics_remaining_hours, topic, topic_remaining_hours - 1)
        end
        calendar_so_far = Map.put(calendar_so_far, day_number, [topic | Map.get(calendar_so_far, day_number, [])])
        create_calendar_recursive(calendar_so_far, topics_remaining_hours, hours_so_far + 1, max_hours_per_day, day_number)
      end
    end

  end

  def create_calendar(topics, max_hours_per_day) do
    create_calendar_recursive(%{}, topics, 0, max_hours_per_day, 5)
  end

  def find_existing_topics_in_calendar(calendar) do
    Enum.reduce(calendar, %{}, fn {_, topics}, acc -> Enum.reduce(topics, acc, fn topic, acc -> Map.put(acc, topic, 1 + Map.get(acc, topic, 0)) end) end)
  end

  def testme_temporary do
    topics = create_topics()
    pupils = create_pupils(10)
    minimum_number_of_hours = 15
    pick_topics_for_pupils(pupils, topics, minimum_number_of_hours)
  end

  def testme_calendar do
    topics = create_topics()
    max_hours_per_day = 10
    create_calendar_recursive(%{}, topics, 0, max_hours_per_day, 5)
  end


  def generate_hours_pupils_week_recursive(_year, _topics_pr_pupil, _pupils, _month_from, month_to, month_to, pupil_accumulator, _day_number, _calendar) do pupil_accumulator end

  def generate_hours_pupils_week_recursive(year, topics_pr_pupil, pupils, month_from, month_to, month_counter, pupil_accumulator, day_number, calendar) do
      the_end_of_month = :calendar.last_day_of_the_month(year, month_counter)
      if day_number > the_end_of_month do
        generate_hours_pupils_week_recursive(year, topics_pr_pupil, pupils, month_from, month_to, month_counter + 1, pupil_accumulator, 1, calendar)
      else
        {:ok, date} = Date.new(year, month_counter, day_number)
        day_of_week = Date.day_of_week(date)
        if day_of_week == 6 or day_of_week == 7 do
          generate_hours_pupils_week_recursive(year, topics_pr_pupil, pupils, month_from, month_to, month_counter, pupil_accumulator, day_number + 1, calendar)
        else
          appearences = Enum.map(pupils, fn pupil ->
            {topics_for_one_student, _hours} = Map.get(topics_pr_pupil, pupil)
            calendar_that_day = Map.get(calendar, day_of_week)
            indexed_calendar_that_day = Enum.with_index(calendar_that_day)
            students_calendar = Enum.filter(indexed_calendar_that_day, fn {topic, _} ->
              Enum.member?(topics_for_one_student, topic) end)
            Enum.map(students_calendar, fn {topic, index} ->
              the_date = %DateTime{year: year, month: month_counter, day: day_number, zone_abbr: "CET", hour:  8 + index, minute: 0, second: 7, microsecond: {0, 0}, utc_offset: 0, std_offset: 0, time_zone: "Europe/Oslo"}
              day_in_year = Date.day_of_year(the_date)
              %AppearenceTemp{pupil: pupil, topic: topic, date: the_date, day_in_year: day_in_year}
            end)
          end)
          generate_hours_pupils_week_recursive(year, topics_pr_pupil, pupils, month_from, month_to, month_counter, [pupil_accumulator | appearences], day_number + 1, calendar)
          end
        end
    end

  def generate_hours_pupils_week(year, topics_pr_pupil, pupils, month_from, month_to, calendar) do
    List.flatten(generate_hours_pupils_week_recursive(year, topics_pr_pupil, pupils, month_from, month_to, month_from, [], 1, calendar))
  end

  def generate_absences_recursive([], acc, _chances_for_full_day, _chances_for_valid, _chanses_for_partly_hour, _chanses_full_hours, _class_id, _school_id, _full_day_dates, _trouble_factor, _number_of_trouble_pupils) do
    acc
  end

  def generate_absences_recursive([aTemp | appearencesTemp], acc, chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, full_day_dates, trouble_factor, number_of_trouble_pupils) do
    # get pupil number
    pupil_number = String.to_integer(String.slice(aTemp.pupil, 6, 10))
    trouble_times = if pupil_number <= number_of_trouble_pupils do trouble_factor else 1 end

    absence_valid = if :rand.uniform(100) <= chances_for_valid * trouble_times do True else False end
    absence_full_day = if :rand.uniform(200) <= chances_for_full_day * trouble_times do True else False end
    absence_full_hours = if absence_full_day == True do False else
        if :rand.uniform(200) <= chanses_for_full_hours do True else False end
      end
    absence_partly_hours = if (absence_full_day == False and absence_full_hours == False) do
      if :rand.uniform(200) <= chanses_for_partly_hour do True else False end end
    if absence_full_day == True or Map.get(full_day_dates, Integer.to_string(pupil_number) <> "_" <> Date.to_string(DateTime.to_date(aTemp.date))) do
      time_absence_valid = if absence_valid == True, do: 0, else: 45
      time_absence_invalid = 45 - time_absence_valid
      new_absence_valid = Map.get(full_day_dates, aTemp.date) || absence_valid
      new_full_days = Map.put(full_day_dates, Integer.to_string(pupil_number) <> "_" <> Date.to_string(DateTime.to_date(aTemp.date)) , new_absence_valid)
      appearence = %Appearence{pupil: aTemp.pupil, topic: aTemp.topic, date: aTemp.date, time_total: 45, absence_valid: time_absence_valid, absence_invalid: time_absence_invalid, full_day: True, class_id: class_id, school_id: school_id}
      generate_absences_recursive(appearencesTemp, [appearence | acc], chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, new_full_days, trouble_factor, number_of_trouble_pupils)
    else
      if absence_full_hours == True do
        time_absence_valid = if absence_valid == True do 0 else 45 end
        time_absence_invalid = 45 - time_absence_valid
        appearence = %Appearence{pupil: aTemp.pupil, topic: aTemp.topic, date: aTemp.date, time_total: 45, absence_valid: time_absence_valid, absence_invalid: time_absence_invalid, full_day: False, class_id: class_id, school_id: school_id}
        generate_absences_recursive(appearencesTemp, [appearence | acc], chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, full_day_dates, trouble_factor, number_of_trouble_pupils)
      else if absence_partly_hours == True do
          random_time = :rand.uniform(45)
          time_absence_valid = if absence_valid == True, do: 0, else: random_time
          time_absence_invalid = unless absence_valid == True, do: 45, else: random_time
          appearence = %Appearence{pupil: aTemp.pupil, topic: aTemp.topic, date: aTemp.date, time_total: 45, absence_valid: time_absence_valid, absence_invalid: time_absence_invalid, full_day: False, class_id: class_id, school_id: school_id}
          generate_absences_recursive(appearencesTemp, [appearence | acc], chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, full_day_dates, trouble_factor, number_of_trouble_pupils)
        else
          # no absence
          appearence = %Appearence{pupil: aTemp.pupil, topic: aTemp.topic, date: aTemp.date, time_total: 45, absence_valid: 0, absence_invalid: 0, full_day: False, class_id: class_id, school_id: school_id}
          generate_absences_recursive(appearencesTemp, [appearence | acc], chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, full_day_dates, trouble_factor, number_of_trouble_pupils)
        end
      end
    end
  end

  def generate_absences(appearencesTemp, chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, trouble_factor, number_of_trouble_pupils) do
    generate_absences_recursive(appearencesTemp, [], chances_for_full_day, chances_for_valid, chanses_for_partly_hour, chanses_for_full_hours, class_id, school_id, %{}, trouble_factor, number_of_trouble_pupils)
  end

  def test_generate_hours_pupil_week do
    pupils = create_pupils(10)
    topics = create_topics()
    topics_pr_pupil = pick_topics_for_pupils(pupils, topics, 20)
    calendar = create_calendar(topics, 10)
    appearences_temp = generate_hours_pupils_week(2024, topics_pr_pupil, pupils, 1, 2, calendar)
    generate_absences(appearences_temp, 10, 10, 10, 10, 1, 1, 2, 2)
  end

  def verify_generated_test_data do
    pupils = create_pupils(10)
    topics = create_topics()
    topics_pr_pupil = pick_topics_for_pupils(pupils, topics, 20)
    calendar = create_calendar(topics, 10)
    appearences_temp = generate_hours_pupils_week(2024, topics_pr_pupil, pupils, 1, 2, calendar)
    chanses_party_hour = 3
    chanses_hole_hours = 1
    chanses_hole_days = 1
    trouble_factor = 15
    appearences = generate_absences(appearences_temp, chanses_hole_days, 10, chanses_party_hour, chanses_hole_hours, 1, 1, trouble_factor, 2)

    # find total absence percentage by adding all absence_valid and absence_invalid and divide by total number of hours
    total_absence = Enum.reduce(appearences, 0, fn aTemp, acc -> acc + aTemp.absence_valid + aTemp.absence_invalid end)
    total_hours = Enum.reduce(appearences, 0, fn aTemp, acc -> acc + aTemp.time_total end)
    percentage = (total_absence / total_hours) * 100
    IO.puts("Total absence percentage: #{percentage}")

    # find total absence on full days by adding all absence_valid and absence_invalid and divide by total number of total_hours above
    total_absence_full_days = Enum.reduce(appearences, 0, fn aTemp, acc -> if aTemp.full_day == True do acc + aTemp.absence_valid + aTemp.absence_invalid else acc end end)
    percentage_full_days = (total_absence_full_days / total_hours) * 100
    IO.puts("Total absence percentage on full days: #{percentage_full_days}")

    # find total absence on full days by counting
    total_absence_full_days = Enum.reduce(appearences, 0, fn aTemp, acc -> if aTemp.full_day == True do acc + 1 else acc end end)
    IO.puts("Total absence on full days: #{total_absence_full_days}")

    # find pupils where absence_valid is 0 and absence_invalid is less than 45 but not 0
    pupils_with_absence = Enum.filter(appearences, fn aTemp -> aTemp.absence_valid == 0 and aTemp.absence_invalid < 45 and aTemp.absence_invalid > 0 end)
    number_of_pupils_with_absence = Enum.count(pupils_with_absence)
    IO.puts("Number of entries with partial absence: #{number_of_pupils_with_absence}")

    # check that pupil_1 has higher absence than average
    pupil_1 = Enum.filter(appearences, fn aTemp -> aTemp.pupil == "pupil_1" end)
    total_absence_pupil_1 = Enum.reduce(pupil_1, 0, fn aTemp, acc -> acc + aTemp.absence_valid + aTemp.absence_invalid end)
    total_hours_pupil_1 = Enum.reduce(pupil_1, 0, fn aTemp, acc -> acc + aTemp.time_total end)
    percentage_pupil_1 = (total_absence_pupil_1 / total_hours_pupil_1) * 100
    IO.puts("Total absence percentage for pupil_1: #{percentage_pupil_1}")

    # check average number of appearences per pupil
    average_appearences = Enum.count(appearences) / Enum.count(pupils)
    IO.puts("Average number of appearences per pupil: #{average_appearences}")

    # check that counting appearences_temps is the same as counting appearences
    number_of_appearences = Enum.count(appearences)
    number_of_appearences_temp = Enum.count(appearences_temp)
    IO.puts("Number of appearences: #{number_of_appearences} and number of appearences_temp: #{number_of_appearences_temp}")


  end

end
