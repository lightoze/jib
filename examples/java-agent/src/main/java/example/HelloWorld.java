/*
 * Copyright 2018 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

package example;

import static spark.Spark.get;
import static spark.Spark.port;

public class HelloWorld {
  public static void main(String[] args) {
    String portEnv = System.getenv("PORT");
    if(portEnv != null) {
      port(Integer.parseInt(portEnv));
    }
    get("/hello", (req, res) -> "Hello World");
  }
}
