<?php

use PHPUnit\Framework\TestListener;
use PHPUnit\Framework\TestResult;
use PHPUnit\TextUI\ResultPrinter;

/**
 * Class: SimpleJsonCounterPrinterPreV7
 * A simple JSON printer which will counts what the number of events
 * and print the results as a JSON object.
 *
 * This one if for PHPUnit version < 7.0, thats when they added the return types
 *
 * @see TestListener
 * @see Printer
 */
class SimpleJsonCounterPrinterPreV7 extends ResultPrinter implements TestListener
{
    /**
     * @param TestResult $result
     */
    public function printResult(TestResult $result)
    {
        parent::printResult($result);

        $this->printJson($result);
    }

    /**
     * @param TestResult $result
     */
    protected function printJson(TestResult $result)
    {
        $this->writeNewObject();
        $this->writeObjectComponent('tests',      \count($result), true);
        $this->writeObjectComponent('assertions', $this->numAssertions);
        $this->writeObjectComponent('errors',     $result->errorCount());
        $this->writeObjectComponent('failures',   $result->failureCount());
        $this->writeObjectComponent('warnings',   $result->warningCount());
        $this->writeObjectComponent('skipped',    $result->skippedCount());
        $this->writeObjectComponent('incomplete', $result->notImplementedCount());
        $this->writeObjectComponent('risky',      $result->riskyCount());
        $this->writeEndOfObject();
        $this->write(PHP_EOL);
    }

    protected function writeNewObject()
    {
        $this->write('{');
    }

    protected function writeEndOfObject()
    {
        $this->write('}');
    }

    /**
     * @param mixed $name
     * @param mixed $value
     * @param bool  $first
     */
    protected function writeObjectComponent($name, $value, $first = false)
    {
        $this->write(sprintf(
            '%s"%s":%s',
            $first ? '' : ',',
            $name,
            $value
        ));
    }
}
